//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
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

    let client: JellyfinClient
    let server: ServerState

    init(server: ServerState) {
        self.client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: server.currentURL),
            sessionDelegate: URLSessionProxyDelegate()
        )
        self.server = server
        super.init()

//        Notifications[.didChangeServerCurrentURI].subscribe(self, selector: #selector(didChangeCurrentLoginURI(_:)))
    }

    @objc
    func didChangeCurrentLoginURI(_ notification: Notification) {
//        guard let newServerState = notification.object as? SwiftfinStore.State.Server else { fatalError("Need to have new state server") }
//        self.server = newServerState
    }

    func fetchUsers() {

        guard let storedServer = try? SwiftfinStore.dataStack.fetchOne(
            From<SwiftfinStore.Models.StoredServer>(),
            Where<SwiftfinStore.Models.StoredServer>("id == %@", server.id)
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

    func remove(user: SwiftfinStore.State.User) {
        fetchUsers()
    }
}
