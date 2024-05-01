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

    struct AddUserButton: View {

        @Binding
        private var serverSelection: ServerSelection

        @Environment(\.isEnabled)
        private var isEnabled

        private let action: (ServerState) -> Void
        private let servers: OrderedSet<ServerState>

        private var selectedServer: ServerState? {
            if case let ServerSelection.server(id: id) = serverSelection,
               let server = servers.first(where: { server in server.id == id })
            {
                return server
            }

            return nil
        }

        init(
            serverSelection: Binding<ServerSelection>,
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
                        if let selectedServer {
                            action(selectedServer)
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
