//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

class UserListViewModel: ViewModel {

	@Published
	var users: [UserState] = []

	var server: ServerState

	init(server: ServerState) {
		self.server = server

		super.init()
        
        Notifications[.didChangeServerCurrentURI].subscribe(self, selector: #selector(didChangeCurrentLoginURI(_:)))
	}

	@objc
	func didChangeCurrentLoginURI(_ notification: Notification) {
		guard let newServerState = notification.object as? ServerState else { fatalError("Need to have new state server") }
		self.server = newServerState
	}

	func fetchUsers() {
		self.users = SessionManager.main.fetchUsers(for: server)
	}

	func login(user: UserState) {
		self.isLoading = true
		SessionManager.main.loginUser(server: server, user: user)
	}

	func remove(user: UserState) {
		SessionManager.main.delete(user: user)
		fetchUsers()
	}
}
