//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

class ServerDetailViewModel: ViewModel {

	@Published
	var server: SwiftfinStore.State.Server

	init(server: SwiftfinStore.State.Server) {
		self.server = server
	}

	func setServerCurrentURI(uri: String) {
		SessionManager.main.setServerCurrentURI(server: server, uri: uri)
			.sink { c in
				print(c)
			} receiveValue: { newServerState in
				self.server = newServerState

				let nc = SwiftfinNotificationCenter.main
				nc.post(name: SwiftfinNotificationCenter.Keys.didChangeServerCurrentURI, object: newServerState)
			}
			.store(in: &cancellables)
	}
}
