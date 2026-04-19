//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

final class ServerConnectionViewModel: ViewModel {

    @Published
    private(set) var server: ServerState

    init(server: ServerState) {
        self.server = server
        super.init()
    }

    // TODO: this could probably be cleaner
    func delete() {
        let userStates = StoredValues[.User.users]
            .filter { $0.serverID == server.id }

        // Note: don't use Server/UserState.delete() to have
        //       all deletions in a single transaction
        do {
            for user in userStates {
                try AnyStoredData.deleteAll(ownerID: user.id)
            }
            try AnyStoredData.deleteAll(ownerID: self.server.id)

            var users = StoredValues[.User.users]
            users.removeAll { $0.serverID == self.server.id }
            StoredValues[.User.users] = users

            var servers = StoredValues[.Server.servers]
            servers.removeAll { $0.id == server.id }
            StoredValues[.Server.servers] = servers

            for user in userStates {
                UserDefaults.userSuite(id: user.id).removeAll()
            }

            Notifications[.didDeleteServer].post(server)
        } catch {
            logger.critical("Unable to delete server: \(server.name)")
        }
    }

    func setCurrentURL(to url: URL) {
        do {
            var servers = StoredValues[.Server.servers]

            guard let index = servers.firstIndex(where: { $0.id == self.server.id }) else {
                throw ErrorMessage("Unable to find server for URL change: \(self.server.name)")
            }

            let existingServer = servers[index]
            let newState = ServerState(
                urls: existingServer.urls,
                currentURL: url,
                name: existingServer.name,
                id: existingServer.id,
                userIDs: existingServer.userIDs
            )

            servers[index] = newState
            StoredValues[.Server.servers] = servers

            Notifications[.didChangeCurrentServerURL].post(newState)

            self.server = newState
        } catch {
            logger.critical("\(error.localizedDescription)")
        }
    }
}
