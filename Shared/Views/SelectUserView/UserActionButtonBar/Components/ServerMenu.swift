//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import OrderedCollections
import SwiftUI

extension SelectUserView {

    struct ServerMenu: View {

        @Default(.selectUserServerSelection)
        private var serverSelection

        @Router
        private var router

        @Environment(\.horizontalSizeClass)
        private var horizontalSizeClass

        private let servers: OrderedSet<ServerState>

        private var selectedServer: ServerState? {
            serverSelection.server(from: servers)
        }

        init(servers: OrderedSet<ServerState>) {
            self.servers = servers
        }

        var body: some View {
            Menu {
                menuItems
            } label: {
                menuLabel
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .menuOrder(.fixed)
        }

        @ViewBuilder
        private var menuItems: some View {
            Section {
                Button(L10n.addServer, systemImage: "plus") {
                    router.route(to: .connectToServer)
                }

                if let selectedServer {
                    Button(L10n.editServer, systemImage: "server.rack") {
                        router.route(
                            to: .editServer(server: selectedServer, isEditing: true),
                            style: .sheet
                        )
                    }
                }
            }

            Picker(L10n.servers, selection: $serverSelection) {

                if servers.count > 1 {
                    Label(L10n.allServers, systemImage: "person.2.fill")
                        .tag(SelectUserServerSelection.all)
                }

                ForEach(servers) { server in
                    VStack(alignment: .leading) {
                        Text(server.name)
                            .foregroundStyle(Color.primary)

                        Text(server.currentURL.absoluteString)
                            .foregroundStyle(Color.secondary)
                    }
                    .tag(SelectUserServerSelection.server(id: server.id))
                }
            }
        }

        @ViewBuilder
        private var menuLabel: some View {
            HStack(spacing: horizontalSizeClass == .compact ? nil : 16) {
                switch serverSelection {
                case .all:
                    Label(L10n.allServers, systemImage: "person.2.fill")
                case let .server(id):
                    if let server = servers.first(where: { $0.id == id }) {
                        Label(server.name, systemImage: "server.rack")
                    } else {
                        Label(L10n.unknown, systemImage: "server.rack")
                    }
                }

                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(.secondary)
                    .font(.subheadline.weight(.semibold))
            }
            .fontWeight(.semibold)
            .foregroundStyle(Color.primary)
        }
    }
}
