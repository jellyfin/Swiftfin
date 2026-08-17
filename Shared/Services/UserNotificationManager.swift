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
                self?.fetchItems(ids: [id])
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
                self?.fetchItems(ids: info.userDataList.compactMap(\.itemID))
            }
            .store(in: &cancellables)

        userSession.serverSocketManager.libraryChanges
            .sink { [weak self] info in
                guard info.isEmpty != true else { return }

                for id in info.itemsRemoved ?? [] {
                    Notifications[.didDeleteItem].post(id)
                }

                self?.fetchItems(ids: info.itemsUpdated ?? [])

                if info.itemsAdded?.isNotEmpty == true ||
                    info.foldersAddedTo?.isNotEmpty == true ||
                    info.foldersRemovedFrom?.isNotEmpty == true
                {
                    Notifications[.didRequestGlobalRefresh].post()
                }
            }
            .store(in: &cancellables)

        userSession.serverSocketManager.userUpdates
            .sink { [weak self] user in
                if let id = user.id {
                    self?.pendingFetches.removeValue(forKey: id)?.cancel()
                }

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

    // MARK: - Items

    private func fetchItems(ids: [String]) {
        guard ids.isNotEmpty, let userSession else { return }

        guard ids.count <= 25 else {
            Notifications[.didRequestGlobalRefresh].post()
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

                for item in items {
                    Notifications[.didChangeItem].post(item)
                }
            } catch {
                logger.error("Unable to fetch changed items", metadata: ["error": .string(error.localizedDescription)])
            }
        }
    }

    // MARK: - Users

    private func fetchUser(id: String) {
        guard let userSession else { return }

        Task {
            do {
                let request = Paths.getUserByID(userID: id)
                let user = try await userSession.client.send(request).value

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
