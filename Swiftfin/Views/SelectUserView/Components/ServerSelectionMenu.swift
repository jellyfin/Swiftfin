//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import OrderedCollections
import SwiftUI

extension SelectUserView {

    struct ServerSelectionMenu: View {

        @Environment(\.colorScheme)
        private var colorScheme

        @Router
        private var router

        @Binding
        private var serverSelection: SelectUserServerSelection

        let selectedServer: ServerState?
        let servers: OrderedSet<ServerState>

        init(
            selection: Binding<SelectUserServerSelection>,
            selectedServer: ServerState?,
            servers: OrderedSet<ServerState>
        ) {
            self._serverSelection = selection
            self.selectedServer = selectedServer
            self.servers = servers
        }

        var body: some View {
            Menu {
                Section {
                    Button(L10n.addServer, systemImage: "plus") {
                        router.route(to: .connectToServer)
                    }

                    if let selectedServer {
                        Button(L10n.editServer, systemImage: "server.rack") {
                            router.route(to: .editServer(server: selectedServer))
                        }
                    }
                }

                Picker(L10n.servers, selection: _serverSelection) {

                    if servers.count > 1 {
                        Label(L10n.allServers, systemImage: "person.2.fill")
                            .tag(SelectUserServerSelection.all)
                    }

                    ForEach(servers.reversed()) { server in
                        Button {
                            Text(server.name)
                            Text(server.currentURL.absoluteString)
                        }
                        .tag(SelectUserServerSelection.server(id: server.id))
                    }
                }
            } label: {
                ZStack {

                    if colorScheme == .light {
                        Color.secondarySystemFill
                    } else {
                        Color.tertiarySystemBackground
                    }

                    HStack {
                        switch serverSelection {
                        case .all:
                            Label(L10n.allServers, systemImage: "person.2.fill")
                        case let .server(id):
                            if let server = servers.first(where: { $0.id == id }) {
                                Label(server.name, systemImage: "server.rack")
                            }
                        }

                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundStyle(.secondary)
                            .font(.subheadline.weight(.semibold))
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.primary)
                }
                .frame(height: 50)
                .frame(maxWidth: 400)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }
}
