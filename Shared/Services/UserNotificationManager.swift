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

    private let maxItemsPerFetch = 100
    private let logger = Logger.swiftfin()

    private var cancellables = Set<AnyCancellable>()

    private weak var userSession: UserSession?

    private func start(userSession: UserSession) {
        stop()
        self.userSession = userSession

        Notifications[.getChangedItemMetadata]
            .publisher
            .sink { [weak self] id in
                self?.fetchItems(ids: [id])
            }
            .store(in: &cancellables)

        Notifications[.getChangedItemUserData]
            .publisher
            .sink { [weak self] id in
                self?.fetchItemUserData(id: id)
            }
            .store(in: &cancellables)

        Notifications[.getChangedUser]
            .publisher
            .sink { [weak self] id in
                self?.fetchUser(id: id)
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
            .sink { user in
                Notifications[.didChangeServerUser].post(user)
            }
            .store(in: &cancellables)

        userSession.serverSocketManager.userDeletions
            .sink { id in
                Notifications[.didDeleteServerUser].post(id)
            }
            .store(in: &cancellables)
    }

    private func stop() {
        cancellables.removeAll()
    }

    // MARK: - Items

    private func fetchItems(ids: [String]) {
        guard ids.isNotEmpty else { return }

        guard ids.count <= maxItemsPerFetch else {
            Notifications[.didRequestGlobalRefresh].post()
            return
        }

        var parameters = Paths.GetItemsParameters()
        parameters.ids = ids

        Task {
            await fetchItems(parameters)
        }
    }

    private func fetchItemUserData(id: String) {
        Task {
            var parameters = Paths.GetItemsParameters()
            parameters.ids = [id]

            guard let item = await fetchItems(parameters).first else { return }

            let parentIDs = [item.seasonID, item.seriesID].compactMap(\.self)

            if parentIDs.isNotEmpty {
                parameters.ids = parentIDs
                await fetchItems(parameters)
            }

            guard item.isFolder == true else { return }

            parameters = Paths.GetItemsParameters()
            parameters.parentID = id
            parameters.isRecursive = true
            await fetchItems(parameters)
        }
    }

    @discardableResult
    private func fetchItems(_ parameters: Paths.GetItemsParameters) async -> [BaseItemDto] {
        guard let userSession else { return [] }

        var parameters = parameters
        parameters.enableUserData = true
        parameters.fields = ItemFields.allCases
        parameters.userID = userSession.user.id

        do {
            let request = Paths.getItems(parameters: parameters)
            let items = try await userSession.client.send(request).value.items ?? []

            for item in items {
                Notifications[.didChangeItem].post(item)
            }

            return items
        } catch {
            logger.error("Unable to fetch changed items", metadata: ["error": .string(error.localizedDescription)])
            return []
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
