//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation
import SwiftUI

final class ServerListViewModel: ViewModel {

    @Published
    var servers: [SwiftfinStore.State.Server] = []

    override init() {
        super.init()

        // Oct. 15, 2021
        // This is a workaround since Stinsen doesn't have the ability to rebuild a root at the time of writing.
        // Feature request issue: https://github.com/rundfunk47/stinsen/issues/33
        // Go to each MainCoordinator and implement the rebuild of the root when receiving the notification
        Notifications[.didPurge].subscribe(self, selector: #selector(didPurge))
    }

    func fetchServers() {
        let servers = try! SwiftfinStore.dataStack.fetchAll(From<SwiftfinStore.Models.StoredServer>())
        self.servers = servers.map(\.state)
    }

    func userTextFor(server: SwiftfinStore.State.Server) -> String {
        if server.userIDs.count == 1 {
            return L10n.oneUser
        } else {
            return L10n.multipleUsers(server.userIDs.count)
        }
    }

    func remove(server: SwiftfinStore.State.Server) {

        guard let storedServer = try? SwiftfinStore.dataStack.fetchOne(
            From<SwiftfinStore.Models.StoredServer>(),
            [Where<SwiftfinStore.Models.StoredServer>("id == %@", server.id)]
        )
        else { fatalError("No stored server for state server?") }

        try! SwiftfinStore.dataStack.perform { transaction in
            transaction.delete(storedServer.users)
            transaction.delete(storedServer)
        }

        fetchServers()
    }

    @objc
    private func didPurge() {
        fetchServers()
    }

    func purge() {
        try? SwiftfinStore.dataStack.perform { transaction in
            let users = try! transaction.fetchAll(From<UserModel>())

            transaction.delete(users)

            let servers = try! transaction.fetchAll(From<ServerModel>())

            for server in servers {
                transaction.delete(server.users)
            }

            transaction.delete(servers)
        }

        fetchServers()

        UserDefaults.generalSuite.removeAll()
        UserDefaults.universalSuite.removeAll()
    }
}
