//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ServerDetailView: View {

    @ObservedObject
    var viewModel: ServerDetailViewModel

    @State
    private var currentServerURI: String

    init(viewModel: ServerDetailViewModel) {
        self.viewModel = viewModel
        self._currentServerURI = State(initialValue: viewModel.server.currentURL.absoluteString)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    L10n.name.text
                    Spacer()
                    Text(viewModel.server.name)
                        .foregroundColor(.secondary)
                }

                Picker(L10n.url, selection: $currentServerURI) {
                    ForEach(viewModel.server.urls.sorted(using: \.absoluteString)) { url in
                        Text(url.absoluteString)
                            .tag(url)
                            .foregroundColor(.secondary)
                    }
                    .onChange(of: currentServerURI) { _ in
                        // TODO: change server url
                    }
                }

                HStack {
                    L10n.version.text
                    Spacer()
                    Text(viewModel.server.version)
                        .foregroundColor(.secondary)
                }

                HStack {
                    L10n.operatingSystem.text
                    Spacer()
                    Text(viewModel.server.os)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(L10n.serverDetails.text)
    }
}
