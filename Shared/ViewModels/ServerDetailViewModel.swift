//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation
import JellyfinAPI

class EditServerViewModel: ViewModel {

    @Published
    var server: ServerState

    init(server: ServerState) {
        self.server = server
    }

    func delete() {
        guard let storedServer = try? dataStack.fetchOne(From<ServerModel>().where(\.$id == server.id)) else {
            fatalError("Unable to find error to delete")
        }

        do {
            try dataStack.perform { transaction in
                transaction.delete(storedServer.users)
                transaction.delete(storedServer)
            }

            Notifications[.didDeleteServer].post(object: server)
        } catch {
            logger.error("Unable to delete server: \(server.name)")
        }
    }

    func setCurrentURL(to url: URL) {
        dataStack.perform { transaction -> ServerModel in
            guard let storedServer = try transaction.fetchOne(From<ServerModel>().where(\.$id == self.server.id)) else {
                throw JellyfinAPIError("Unable to find server for URL change: \(self.server.name)")
            }
            storedServer.currentURL = url

            return storedServer
        } success: { storedServer in
            Notifications[.didChangeCurrentServerURL].post(object: storedServer.state)
        } failure: { error in
            self.logger.error("\(error.localizedDescription)")
        }
    }
}
