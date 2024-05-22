//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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

        private var content: some View {
            HStack(alignment: .center, spacing: EdgeInsets.edgePadding) {

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

                HStack {

                    Text("Add User")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(isEnabled ? .primary : .secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }

        var body: some View {
            if serverSelection == .all {
                Menu {

                    Text("Select Server")

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
                Button {
                    if let selectedServer {
                        action(selectedServer)
                    }
                } label: {
                    content
                }
                .disabled(!isEnabled)
                .foregroundStyle(.primary, .secondary)
            }
        }
    }
}
