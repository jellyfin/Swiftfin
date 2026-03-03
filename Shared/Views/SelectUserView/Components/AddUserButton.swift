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

    struct AddUserButton: View {

        @Environment(\.isEnabled)
        private var isEnabled

        let displayType: LibraryDisplayType
        let selectedServer: ServerState?
        let servers: OrderedSet<ServerState>
        let action: (ServerState) -> Void

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
                switch displayType {
                case .list:
                    listLabel
                default:
                    gridLabel
                }
            }
            #if os(iOS)
            .buttonStyle(.plain)
            #else
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
            #endif
        }

        @ViewBuilder
        private var plusIcon: some View {
            ZStack {
                Color.clear
                    .background(.thinMaterial)
                    .posterShadow()

                RelativeSystemImageView(systemName: "plus")
                    .foregroundStyle(.secondary)
            }
            .clipShape(.circle)
            .hoverEffect(.highlight)
            .aspectRatio(1, contentMode: .fill)
        }

        @ViewBuilder
        private var gridLabel: some View {
            VStack(alignment: .center) {
                plusIcon

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
        }

        @ViewBuilder
        private var listLabel: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                plusIcon
                    .frame(width: 80)
                    .padding(.vertical, 8)
            } content: {
                Text(L10n.addUser)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(isEnabled ? .primary : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .isSeparatorVisible(false)
            .onSelect {
                if let selectedServer {
                    action(selectedServer)
                }
            }
        }
    }
}
