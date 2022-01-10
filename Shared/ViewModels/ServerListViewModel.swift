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

		// Oct. 15, 2021
		// This is a workaround since Stinsen doesn't have the ability to rebuild a root at the time of writing.
		// Feature request issue: https://github.com/rundfunk47/stinsen/issues/33
		// Go to each MainCoordinator and implement the rebuild of the root when receiving the notification
		let nc = SwiftfinNotificationCenter.main
		nc.addObserver(self, selector: #selector(didPurge), name: SwiftfinNotificationCenter.Keys.didPurge, object: nil)
	}

	func fetchServers() {
		self.servers = SessionManager.main.fetchServers()
	}

	func userTextFor(server: SwiftfinStore.State.Server) -> String {
		if server.userIDs.count == 1 {
			return "1 user"
		} else {
			return "\(server.userIDs.count) users"
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
