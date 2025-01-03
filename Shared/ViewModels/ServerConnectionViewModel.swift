//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation
import JellyfinAPI

class ServerConnectionViewModel: ViewModel {

    @Published
    var server: ServerState

    init(server: ServerState) {
        self.server = server
    }

    // TODO: this could probably be cleaner
    func delete() {

        guard let storedServer = try? dataStack.fetchOne(From<ServerModel>().where(\.$id == server.id)) else {
            logger.critical("Unable to find server to delete")
            return
        }

        let userStates = storedServer.users.map(\.state)

        // Note: don't use Server/UserState.delete() to have
        //       all deletions in a single transaction
        do {
            try dataStack.perform { transaction in

                /// Delete stored data for all users
                for user in storedServer.users {
                    let storedDataClause = AnyStoredData.fetchClause(ownerID: user.id)
                    let storedData = try transaction.fetchAll(storedDataClause)

                    transaction.delete(storedData)
                }

                transaction.delete(storedServer.users)
                transaction.delete(storedServer)
            }

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
            let newState = try dataStack.perform { transaction in
                guard let storedServer = try transaction.fetchOne(From<ServerModel>().where(\.$id == self.server.id)) else {
                    throw JellyfinAPIError("Unable to find server for URL change: \(self.server.name)")
                }
                storedServer.currentURL = url

                return storedServer.state
            }

            Notifications[.didChangeCurrentServerURL].post(newState)

            self.server = newState
        } catch {
            logger.critical("\(error.localizedDescription)")
        }
    }
}
