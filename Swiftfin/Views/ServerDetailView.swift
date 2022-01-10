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
	@State
	var currentServerURI: String

	init(viewModel: ServerDetailViewModel) {
		self.viewModel = viewModel
		self.currentServerURI = viewModel.server.currentURI
	}

	var body: some View {
		Form {
			Section(header: Text("Server Details")) {
				HStack {
					Text("Name")
					Spacer()
					Text(viewModel.server.name)
						.foregroundColor(.secondary)
				}

				Picker("URI", selection: $currentServerURI) {
					ForEach(viewModel.server.uris.sorted(), id: \.self) { uri in
						Text(uri).tag(uri)
							.foregroundColor(.secondary)
					}.onChange(of: currentServerURI) { newValue in
						viewModel.setServerCurrentURI(uri: newValue)
					}
				}

				HStack {
					Text("Version")
					Spacer()
					Text(viewModel.server.version)
						.foregroundColor(.secondary)
				}

				HStack {
					Text("Operating System")
					Spacer()
					Text(viewModel.server.os)
						.foregroundColor(.secondary)
				}
			}
		}
	}
}
