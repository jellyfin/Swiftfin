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

        @Environment(\.horizontalSizeClass)
        private var horizontalSizeClass

        @Router
        private var router

        let servers: OrderedSet<ServerState>

        var body: some View {
            Menu {
                Section {
                    Button(L10n.addServer, systemImage: "plus") {
                        router.route(to: .connectToServer)
                    }

                    if let selectedServer = serverSelection.server(from: servers) {
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
                        Button {} label: {
                            Text(server.name)
                            Text(server.currentURL.absoluteString)
                        }
                        .tag(SelectUserServerSelection.server(id: server.id))
                    }
                }
            } label: {
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
                        .font(.subheadline)
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .menuOrder(.fixed)
        }
    }
}
