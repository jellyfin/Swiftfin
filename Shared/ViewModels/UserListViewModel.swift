//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Factory
import Foundation
import JellyfinAPI
import Pulse
import SwiftUI

class UserListViewModel: ViewModel {

    @Published
    private(set) var users: [UserState] = []
    @Published
    private(set) var server: ServerState

    var client: JellyfinClient {
        JellyfinClient(
            configuration: .swiftfinConfiguration(url: server.currentURL),
            sessionDelegate: URLSessionProxyDelegate()
        )
    }

    init(server: ServerState) {
        self.server = server
        super.init()

        Notifications[.didChangeCurrentServerURL]
            .publisher
            .sink { [weak self] notification in
                guard let serverState = notification.object as? SwiftfinStore.State.Server else {
                    return
                }
                self?.server = serverState
            }
            .store(in: &cancellables)
    }

    func fetchUsers() {

        guard let storedServer = try? SwiftfinStore.dataStack.fetchOne(
            From<ServerModel>(),
            Where<ServerModel>("id == %@", server.id)
        )
        else { fatalError("No stored server associated with given state server?") }

        users = storedServer.users
            .map(\.state)
            .sorted(using: \.username)
    }

    func signIn(user: UserState) {
        Defaults[.lastServerUserID] = user.id
        Container.userSession.reset()
        Notifications[.didSignIn].post()
    }

    func remove(user: UserState) {
        guard let storedUser = try? SwiftfinStore.dataStack.fetchOne(
            From<SwiftfinStore.Models.StoredUser>(),
            [Where<SwiftfinStore.Models.StoredUser>("id == %@", user.id)]
        ) else {
            logger.error("Unable to find user to delete")
            return
        }

        let transaction = SwiftfinStore.dataStack.beginUnsafe()
        transaction.delete(storedUser)

        do {
            try transaction.commitAndWait()
            fetchUsers()
        } catch {
            logger.error("Unable to delete user")
        }
    }
}
