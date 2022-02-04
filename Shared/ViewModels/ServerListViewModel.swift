//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

class ServerListViewModel: ObservableObject {

	@Published
	var servers: [SwiftfinStore.State.Server] = []

	init() {
        
        Notifications[.didPurge].subscribe(self, selector: #selector(didPurge))
	}

	func fetchServers() {
		self.servers = SessionManager.main.fetchServers()
	}

	func userTextFor(server: SwiftfinStore.State.Server) -> String {
		if server.userIDs.count == 1 {
			return L10n.oneUser
		} else {
			return L10n.multipleUsers(server.userIDs.count)
		}
	}

	func remove(server: SwiftfinStore.State.Server) {
		SessionManager.main.delete(server: server)
		fetchServers()
	}

	@objc
	private func didPurge() {
		fetchServers()
	}
}
