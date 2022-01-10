//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ServerDetailView: View {

	@ObservedObject
	var viewModel: ServerDetailViewModel

	var body: some View {
		Form {
            Section(header: L10n.serverDetails.text) {
				HStack {
                    L10n.name.text
					Spacer()
					Text(SessionManager.main.currentLogin.server.name)
						.foregroundColor(.secondary)
				}
				.focusable()

				HStack {
                    L10n.url.text
					Spacer()
					Text(SessionManager.main.currentLogin.server.currentURI)
						.foregroundColor(.secondary)
				}

				HStack {
                    L10n.version.text
					Spacer()
					Text(SessionManager.main.currentLogin.server.version)
						.foregroundColor(.secondary)
				}

				HStack {
                    L10n.operatingSystem.text
					Spacer()
					Text(SessionManager.main.currentLogin.server.os)
						.foregroundColor(.secondary)
				}
			}
		}
	}
}
