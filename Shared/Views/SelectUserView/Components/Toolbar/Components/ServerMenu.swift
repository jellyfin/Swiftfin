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

        @AdaptiveLayout
        private var viewLayout

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
                                to: .editLocalServer(server: selectedServer, isEditing: true),
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
                            Text(server.effectiveServerURL.absoluteString)
                        }
                        .tag(SelectUserServerSelection.server(id: server.id))
                    }
                }
            } label: {
                HStack(spacing: viewLayout.isCompact ? nil : 16) {
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
                .if(viewLayout.isAccessibilitySize) { label in
                    label.labelStyle(.titleOnly)
                }
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, viewLayout.value(standard: 12, large: 0))
                .padding(.horizontal, viewLayout.value(standard: 16, large: 0))
                .frame(maxWidth: .infinity, minHeight: viewLayout.controlHeight)
            }
            .foregroundStyle(.primary, .secondary)
            .menuOrder(.fixed)
            .symbolRenderingMode(.monochrome)
            .backport
            .glassEffect(in: .capsule)
        }
    }
}
