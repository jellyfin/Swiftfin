//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import OrderedCollections
import SwiftUI

extension SelectUserView {

    struct ServerSelectionMenu: View {

        // MARK: - Observed & Environment Objects

        @Router
        private var router

        // MARK: - Server Selection

        @Binding
        private var serverSelection: SelectUserServerSelection

        private let selectedServer: ServerState?
        private let servers: OrderedSet<ServerState>

        // MARK: - Initializer

        init(
            selection: Binding<SelectUserServerSelection>,
            selectedServer: ServerState?,
            servers: OrderedSet<ServerState>
        ) {
            self._serverSelection = selection
            self.selectedServer = selectedServer
            self.servers = servers
        }

        @ViewBuilder
        private var label: some View {
            HStack(spacing: 16) {
                if let selectedServer {
                    Image(systemName: "server.rack")

                    Text(selectedServer.name)
                } else {
                    Image(systemName: "person.2.fill")

                    Text(L10n.allServers)
                }

                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(.secondary)
                    .font(.subheadline.weight(.semibold))
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.primary)
            .frame(width: 400, height: 50)
        }

        // MARK: - Body

        var body: some View {
            Menu {
                Picker(L10n.servers, selection: _serverSelection) {
                    ForEach(servers) { server in
                        Button {
                            Text(server.name)
                            Text(server.currentURL.absoluteString)
                        }
                        .tag(SelectUserServerSelection.server(id: server.id))
                    }

                    if servers.count > 1 {
                        Label(L10n.allServers, systemImage: "person.2.fill")
                            .tag(SelectUserServerSelection.all)
                    }
                }
                Section {
                    if let selectedServer {
                        Button(L10n.editServer, systemImage: "server.rack") {
                            router.route(
                                to: .editServer(server: selectedServer, isEditing: true),
                                style: .sheet
                            )
                        }
                    }

                    Button(L10n.addServer, systemImage: "plus") {
                        router.route(to: .connectToServer)
                    }
                }
            } label: {
                label
            }
            .menuOrder(.fixed)
        }
    }
}
