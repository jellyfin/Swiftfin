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

    struct AddUserRow: View {

        @Environment(\.colorScheme)
        private var colorScheme
        @Environment(\.isEnabled)
        private var isEnabled

        @Binding
        private var serverSelection: SelectUserServerSelection

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
        private var rowContent: some View {
            HStack {

                Text(L10n.addUser)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(isEnabled ? .primary : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
        }

        @ViewBuilder
        private var rowLeading: some View {
            ZStack {
                Group {
                    if colorScheme == .light {
                        Color.secondarySystemFill
                    } else {
                        Color.tertiarySystemBackground
                    }
                }
                .posterShadow()

                RelativeSystemImageView(systemName: "plus")
                    .foregroundStyle(.secondary)
            }
            .aspectRatio(1, contentMode: .fill)
            .clipShape(.circle)
            .frame(width: 80)
            .padding(.vertical, 8)
        }

        @ViewBuilder
        private var content: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                rowLeading
            } content: {
                rowContent
            }
            .isSeparatorVisible(false)
            .onSelect {
                if let selectedServer {
                    action(selectedServer)
                }
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
                .disabled(!isEnabled)
                .foregroundStyle(.primary, .secondary)
            } else {
                content
                    .disabled(!isEnabled)
                    .foregroundStyle(.primary, .secondary)
            }
        }
    }
}
