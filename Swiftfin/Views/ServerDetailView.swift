//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

struct ServerDetailView: View {

    @State
    private var currentServerURL: URL

    @StateObject
    private var viewModel: ServerDetailViewModel

    init(server: ServerState) {
        self._viewModel = StateObject(wrappedValue: ServerDetailViewModel(server: server))
        self._currentServerURL = State(initialValue: server.currentURL)
    }

    var body: some View {
        Form {
            Section {

                TextPairView(
                    leading: L10n.name,
                    trailing: viewModel.server.name
                )

                Picker(L10n.url, selection: $currentServerURL) {
                    ForEach(viewModel.server.urls.sorted(using: \.absoluteString)) { url in
                        Text(url.absoluteString)
                            .tag(url)
                            .foregroundColor(.secondary)
                    }
                    .onChange(of: currentServerURL) { _ in
                        // TODO: change server url
                        viewModel.setCurrentServerURL(to: currentServerURL)
                    }
                }

                TextPairView(
                    leading: L10n.version,
                    trailing: viewModel.server.version
                )

                TextPairView(
                    leading: L10n.operatingSystem,
                    trailing: viewModel.server.os
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(L10n.server)
    }
}
