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

    struct AddUserButton: View {

        @Binding
        private var serverSelection: SelectUserServerSelection

        @Environment(\.isEnabled)
        private var isEnabled

        private let action: (ServerState) -> Void
        private let servers: OrderedSet<ServerState>

        private var selectedServer: ServerState? {
            if case let SelectUserServerSelection.server(id: id) = serverSelection,
               let server = servers.first(where: { server in server.id == id })
            {
                return server
            }

            return nil
        }

        init(
            serverSelection: Binding<SelectUserServerSelection>,
            servers: OrderedSet<ServerState>,
            action: @escaping (ServerState) -> Void
        ) {
            self._serverSelection = serverSelection
            self.action = action
            self.servers = servers
        }

        @ViewBuilder
        private var content: some View {
            ZStack {
                Color.secondarySystemFill

                RelativeSystemImageView(systemName: "plus")
                    .foregroundStyle(.secondary)
            }
            .clipShape(.circle)
            .aspectRatio(1, contentMode: .fill)
            .hoverEffect(.highlight)

            Text(L10n.addUser)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(isEnabled ? .primary : .secondary)

            if serverSelection == .all {
                // For layout, not to be localized
                Text("Hidden")
                    .font(.footnote)
                    .hidden()
            }
        }

        var body: some View {
            if serverSelection == .all {
                Menu {
                    Text(L10n.selectServer)

                    ForEach(servers) { server in
                        Button {
                            action(server)
                        } label: {
                            Text(server.name)
                            Text(server.currentURL.absoluteString)
                        }
                    }
                } label: {
                    content
                }
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
            } else {
                Button {
                    if let selectedServer {
                        action(selectedServer)
                    }
                } label: {
                    content
                }
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
            }
        }
    }
}
