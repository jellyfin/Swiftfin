//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import OrderedCollections
import SwiftUI

extension SelectUserView {

    struct AddUserBottomButton: View {

        // MARK: Properties

        private let action: (ServerState) -> Void
        private let selectedServer: ServerState?
        private let servers: OrderedSet<ServerState>

        // MARK: View Builders

        @ViewBuilder
        private var label: some View {
            Label(L10n.addUser, systemImage: "plus")
                .foregroundStyle(Color.primary)
                .font(.body.weight(.semibold))
                .labelStyle(.iconOnly)
                .frame(width: 50, height: 50)
        }

        // MARK: - Initializer

        init(
            selectedServer: ServerState?,
            servers: OrderedSet<ServerState>,
            action: @escaping (ServerState) -> Void
        ) {
            self.action = action
            self.selectedServer = selectedServer
            self.servers = servers
        }

        // MARK: Body

        var body: some View {
            ConditionalMenu(
                tracking: selectedServer,
                action: action
            ) {
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
                label
            }
        }
    }
}
