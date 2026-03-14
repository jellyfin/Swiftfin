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

    struct AddUserGridButton: View {

        @Environment(\.isEnabled)
        private var isEnabled

        let selectedServer: ServerState?
        let servers: OrderedSet<ServerState>
        let action: (ServerState) -> Void

        @ViewBuilder
        private var label: some View {
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

            if selectedServer == nil {
                // For layout, not to be localized
                Text("Hidden")
                    .font(.footnote)
                    .hidden()
            }
        }

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
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
        }
    }
}
