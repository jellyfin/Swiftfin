//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Stinsen
import SwiftUI

struct ConnectToServerView: View {

	@StateObject
	var viewModel: ConnectToServerViewModel
	@State
	var uri = ""

	@Default(.defaultHTTPScheme)
	var defaultHTTPScheme

	var body: some View {
		List {
			Section {
				TextField(L10n.serverURL, text: $uri)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.keyboardType(.URL)
					.onAppear {
						if uri == "" {
							uri = "\(defaultHTTPScheme.rawValue)://"
						}
					}

				Button {
					viewModel.connectToServer(uri: uri)
				} label: {
					HStack {
						L10n.connect.text
						Spacer()
						if viewModel.isLoading {
							ProgressView()
						}
					}
				}
				.disabled(viewModel.isLoading || uri.isEmpty)
			} header: {
                L10n.connectToJellyfinServer.text
			}

			Section(header: L10n.localServers.text) {
				if viewModel.searching {
					ProgressView()
				}
				ForEach(viewModel.discoveredServers.sorted(by: { $0.name < $1.name }), id: \.id) { discoveredServer in
					Button(action: {
						viewModel.connectToServer(uri: discoveredServer.url.absoluteString)
					}, label: {
						HStack {
							Text(discoveredServer.name)
								.font(.headline)
							Text("• \(discoveredServer.host)")
								.font(.subheadline)
								.foregroundColor(.secondary)
							Spacer()
							if viewModel.isLoading {
								ProgressView()
							}
						}

					})
				}
			}
			.onAppear(perform: self.viewModel.discoverServers)
			.headerProminence(.increased)
		}
		.alert(item: $viewModel.errorMessage) { _ in
			Alert(title: Text(viewModel.alertTitle),
                  message: Text(viewModel.errorMessage?.displayMessage ?? L10n.unknownError),
			      dismissButton: .cancel())
		}
		.navigationTitle(L10n.connect)
	}
}
