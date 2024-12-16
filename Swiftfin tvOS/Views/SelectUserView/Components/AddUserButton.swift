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

        var body: some View {
            VStack {
                Button {
                    if let selectedServer {
                        action(selectedServer)
                    }
                } label: {
                    ZStack {
                        Color.secondarySystemFill

                        RelativeSystemImageView(systemName: "plus")
                            .foregroundStyle(.secondary)
                    }
                    .clipShape(.circle)
                    .aspectRatio(1, contentMode: .fill)
                }
                .buttonStyle(.card)
                .buttonBorderShape(.circleBackport)
                .disabled(!isEnabled)

                Text(L10n.addUser)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(isEnabled ? .primary : .secondary)

                if serverSelection == .all {
                    Text(L10n.hidden)
                        .font(.footnote)
                        .hidden()
                }
            }
        }
    }
}
