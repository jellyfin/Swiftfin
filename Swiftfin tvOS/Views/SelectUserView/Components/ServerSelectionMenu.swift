//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SelectUserView {

    struct ServerSelectionMenu: View {

        // MARK: - Observed & Environment Objects

        @EnvironmentObject
        private var router: SelectUserCoordinator.Router

        @ObservedObject
        private var viewModel: SelectUserViewModel

        // MARK: - Server Selection

        @Binding
        private var serverSelection: SelectUserServerSelection

        private var selectedServer: ServerState? {
            if case let SelectUserServerSelection.server(id: id) = serverSelection,
               let server = viewModel.servers.keys.first(where: { server in server.id == id })
            {
                return server
            }

            return nil
        }

        // MARK: - Initializer

        init(
            selection: Binding<SelectUserServerSelection>,
            viewModel: SelectUserViewModel
        ) {
            self._serverSelection = selection
            self.viewModel = viewModel
        }

        // MARK: - Body

        var body: some View {
            Menu {
                Picker(L10n.servers, selection: _serverSelection) {
                    ForEach(viewModel.servers.keys) { server in
                        Button {
                            Text(server.name)
                            Text(server.currentURL.absoluteString)
                        }
                        .tag(SelectUserServerSelection.server(id: server.id))
                    }
                    if viewModel.servers.keys.count > 1 {
                        Label(L10n.allServers, systemImage: "person.2.fill")
                            .tag(SelectUserServerSelection.all)
                    }
                }
                Section {
                    if let selectedServer {
                        Button(L10n.editServer, systemImage: "server.rack") {
                            router.route(to: \.editServer, selectedServer)
                        }
                    }
                    Button(L10n.addServer, systemImage: "plus") {
                        router.route(to: \.connectToServer)
                    }
                }
            } label: {
                HStack(spacing: 16) {
                    switch serverSelection {
                    case .all:
                        Image(systemName: "person.2.fill")
                        Text(L10n.allServers)
                    case let .server(id):
                        if let server = viewModel.servers.keys.first(where: { $0.id == id }) {
                            Image(systemName: "server.rack")
                            Text(server.name)
                        }
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.subheadline.weight(.semibold))
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.primary)
                .frame(width: 400, height: 50)
            }
            .menuOrder(.fixed)
        }
    }
}
