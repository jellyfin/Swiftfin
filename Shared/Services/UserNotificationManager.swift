//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import Logging

@MainActor
final class UserNotificationManager {

    private enum Source: String {
        case manual = "Manual"
        case socket = "Socket"
    }

    private let logger = Logger.swiftfin()

    private var cancellables = Set<AnyCancellable>()
    private var pendingFetches: [String: Task<Void, Never>] = [:]

    private weak var userSession: UserSession?

    private func start(userSession: UserSession) {

        stop()

        self.userSession = userSession

        Publishers.Merge(
            Notifications[.getChangedItemMetadata].publisher,
            Notifications[.getChangedItemUserData].publisher
        )
        .sink { [weak self] id in
            self?.waitForSocket(id) {
                self?.fetchItems(ids: [id], from: .manual)
            }
        }
        .store(in: &cancellables)

        Notifications[.getChangedUser]
            .publisher
            .sink { [weak self] id in
                self?.waitForSocket(id) {
                    self?.fetchUser(id: id)
                }
            }
            .store(in: &cancellables)

        Notifications[.didChangeServerUser]
            .publisher
            .sink { [weak self] user in
                guard let userSession = self?.userSession, user.id == userSession.user.id else { return }
                userSession.user.updateUserData(user)
            }
            .store(in: &cancellables)

        userSession.serverSocketManager.userDataChanges
            .sink { [weak self] info in
                guard info.userID == nil || info.userID == self?.userSession?.user.id else { return }
                self?.fetchItems(ids: info.userDataList.compactMap(\.itemID), from: .socket)
            }
            .store(in: &cancellables)

        userSession.serverSocketManager.libraryChanges
            .sink { [weak self] info in
                guard info.isEmpty != true else { return }

                self?.deleteItems(ids: info.itemsRemoved ?? [])
                self?.fetchItems(ids: info.itemsUpdated ?? [], from: .socket)

                let changedParents = Set(
                    (info.foldersAddedTo ?? []) +
                        (info.foldersRemovedFrom ?? []) +
                        (info.collectionFolders ?? [])
                )

                let hasStructuralChange = info.itemsAdded?.isNotEmpty == true ||
                    info.foldersAddedTo?.isNotEmpty == true ||
                    info.foldersRemovedFrom?.isNotEmpty == true

                if hasStructuralChange {
                    if changedParents.isNotEmpty {
                        self?.requestLibraryRefresh(ids: Array(changedParents))
                    } else {
                        self?.requestGlobalRefresh(reason: "Library changed")
                    }
                }
            }
            .store(in: &cancellables)

        userSession.serverSocketManager.userUpdates
            .sink { [weak self] user in
                if let id = user.id {
                    self?.pendingFetches.removeValue(forKey: id)?.cancel()
                }

                self?.logger.info("Updated user", metadata: ["source": .string(Source.socket.rawValue)])

                Notifications[.didChangeServerUser].post(user)
            }
            .store(in: &cancellables)

        userSession.serverSocketManager.userDeletions
            .sink { id in
                Notifications[.didDeleteServerUser].post(id)
            }
            .store(in: &cancellables)

        userSession.serverSocketManager.serverRestarts
            .sink {
                Notifications[.didServerRestart].post()
            }
            .store(in: &cancellables)

        userSession.serverSocketManager.serverShutdowns
            .sink {
                Notifications[.didServerShutdown].post()
            }
            .store(in: &cancellables)
    }

    private func stop() {
        cancellables.removeAll()
        pendingFetches.values.forEach { $0.cancel() }
        pendingFetches.removeAll()
    }

    /// Wait to see if the Socket will give us the update automatically before calling it manually
    private func waitForSocket(_ id: String, otherwise fetch: @escaping () -> Void) {
        pendingFetches[id]?.cancel()
        pendingFetches[id] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }

            self?.pendingFetches[id] = nil
            fetch()
        }
    }

    private func requestGlobalRefresh(reason: String) {
        logger.info("Requesting global refresh", metadata: ["reason": .string(reason)])

        Notifications[.didRequestGlobalRefresh].post()
    }

    private func requestLibraryRefresh(ids: [String]) {
        logger.info("Requesting library refresh", metadata: ["count": .stringConvertible(ids.count)])

        Notifications[.didRequestLibraryRefresh].post(ids)
    }

    // MARK: - Items

    private func fetchItems(ids: [String], from source: Source) {
        guard ids.isNotEmpty, let userSession else { return }

        guard ids.count <= 25 else {
            requestGlobalRefresh(reason: "\(ids.count) items changed")
            return
        }

        for id in ids {
            pendingFetches.removeValue(forKey: id)?.cancel()
        }

        var parameters = Paths.GetItemsParameters()
        parameters.ids = ids
        parameters.enableUserData = true
        parameters.fields = ItemFields.allCases
        parameters.userID = userSession.user.id

        Task {
            do {
                let request = Paths.getItems(parameters: parameters)
                let items = try await userSession.client.send(request).value.items ?? []

                logger.info(
                    "Updated items",
                    metadata: [
                        "source": .string(source.rawValue),
                        "count": .stringConvertible(items.count),
                    ]
                )

                for item in items {
                    Notifications[.didChangeItem].post(item)
                }
            } catch {
                logger.error("Unable to fetch changed items", metadata: ["error": .string(error.localizedDescription)])
            }
        }
    }

    private func deleteItems(ids: [String]) {
        guard ids.isNotEmpty else { return }

        logger.info("Deleted items", metadata: ["count": .stringConvertible(ids.count)])

        for id in ids {
            Notifications[.didDeleteItem].post(id)
        }
    }

    // MARK: - Users

    private func fetchUser(id: String) {
        guard let userSession else { return }

        Task {
            do {
                let request = Paths.getUserByID(userID: id)
                let user = try await userSession.client.send(request).value

                logger.info("Updated user", metadata: ["source": .string(Source.manual.rawValue)])

                Notifications[.didChangeServerUser].post(user)
            } catch {
                logger.error("Unable to fetch changed user", metadata: ["error": .string(error.localizedDescription)])
            }
        }
    }
}

extension UserNotificationManager: UserSessionService {

    func willStart(userSession: UserSession) async {
        start(userSession: userSession)
    }

    func willStop(userSession: UserSession) {
        stop()
    }
}
