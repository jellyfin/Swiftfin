//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

class UserListViewModel: ViewModel {

    @Published
    var users: [SwiftfinStore.State.User] = []

    var server: SwiftfinStore.State.Server

    init(server: SwiftfinStore.State.Server) {
        self.server = server

        super.init()

        JellyfinAPIAPI.basePath = server.currentURI
        Notifications[.didChangeServerCurrentURI].subscribe(self, selector: #selector(didChangeCurrentLoginURI(_:)))
    }

    @objc
    func didChangeCurrentLoginURI(_ notification: Notification) {
        guard let newServerState = notification.object as? SwiftfinStore.State.Server else { fatalError("Need to have new state server") }
        self.server = newServerState
    }

    func fetchUsers() {
        self.users = SessionManager.main.fetchUsers(for: server)
    }

    func signIn(user: SwiftfinStore.State.User) {
        self.isLoading = true
        SessionManager.main.signInUser(server: server, user: user)
    }

    func remove(user: SwiftfinStore.State.User) {
        SessionManager.main.delete(user: user)
        fetchUsers()
    }
}
