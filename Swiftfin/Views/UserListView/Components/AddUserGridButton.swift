//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import OrderedCollections
import SwiftUI

extension UserListView {

    struct AddUserButton: View {

        @Binding
        private var serverSelection: ServerSelectionOption

        @Environment(\.isEnabled)
        private var isEnabled

        private let action: (ServerState) -> Void
        private let servers: OrderedSet<ServerState>

        init(
            serverSelection: Binding<ServerSelectionOption>,
            servers: OrderedSet<ServerState>,
            action: @escaping (ServerState) -> Void
        ) {
            self._serverSelection = serverSelection
            self.action = action
            self.servers = servers
        }

        private var content: some View {
            SystemImageContentView(systemName: "plus")
                .background(color: Color.tertiarySystemBackgorund)
                .aspectRatio(1, contentMode: .fill)
                .clipShape(.circle)
        }

        var body: some View {
            VStack(alignment: .center) {
                if serverSelection == .all {
                    Menu {
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
                } else {
                    Button {
                        if case let ServerSelectionOption.server(id: id) = serverSelection,
                           let server = servers.first(where: { $0.id == id })
                        {
                            action(server)
                        }
                    } label: {
                        content
                    }
                    .disabled(!isEnabled)
                }

                Text("Add User")
                    .fontWeight(.semibold)
                    .foregroundStyle(isEnabled ? .primary : .secondary)
            }
        }
    }
}
