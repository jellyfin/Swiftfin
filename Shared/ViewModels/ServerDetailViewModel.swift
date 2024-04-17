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

class ServerDetailViewModel: ViewModel {

    @Published
    var server: ServerState

    init(server: ServerState) {
        self.server = server
    }

    func setCurrentServerURL(to url: URL) {

        guard let storedServer = try? SwiftfinStore.dataStack.fetchOne(
            From<ServerModel>(),
            [Where<ServerModel>("id == %@", server.id)]
        ) else {
            logger.error("Unable to find server")
            return
        }

        guard storedServer.urls.contains(url) else {
            logger.error("Server did not have matching URL")
            return
        }

        let transaction = SwiftfinStore.dataStack.beginUnsafe()

        guard let editServer = transaction.edit(storedServer) else {
            logger.error("Unable to create edit server instance")
            return
        }

        editServer.currentURL = url

        do {
            try transaction.commitAndWait()

            Notifications[.didChangeCurrentServerURL].post(object: editServer.state)
        } catch {
            logger.error("Unable to edit server")
        }
    }
}
