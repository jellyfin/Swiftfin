//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension SelectUserView {

    struct UserRow: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.colorScheme)
        private var colorScheme
        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isSelected)
        private var isSelected

        private let user: UserState
        private let server: ServerState
        private let showServer: Bool
        private let action: () -> Void
        private let onDelete: () -> Void

        init(
            user: UserState,
            server: ServerState,
            showServer: Bool,
            action: @escaping () -> Void,
            onDelete: @escaping () -> Void
        ) {
            self.user = user
            self.server = server
            self.showServer = showServer
            self.action = action
            self.onDelete = onDelete
        }

        private var labelForegroundStyle: some ShapeStyle {
            guard isEditing else { return .primary }

            return isSelected ? .primary : .secondary
        }

        @ViewBuilder
        private var personView: some View {
            ZStack {
                Group {
                    if colorScheme == .light {
                        Color.secondarySystemFill
                    } else {
                        Color.tertiarySystemBackground
                    }
                }
                .posterShadow()

                RelativeSystemImageView(systemName: "person.fill", ratio: 0.5)
                    .foregroundStyle(.secondary)
            }
            .clipShape(.circle)
            .aspectRatio(1, contentMode: .fill)
        }

        @ViewBuilder
        private var userImage: some View {
            ZStack {
                Color.clear

                UserProfileImage(
                    userID: user.id,
                    source: user.profileImageSource(
                        client: server.client,
                        maxWidth: 120
                    ),
                    pipeline: .Swiftfin.local
                )

                if isEditing {
                    Color.black
                        .opacity(isSelected ? 0 : 0.5)
                }
            }
            .aspectRatio(contentMode: .fill)
            .clipShape(.circle)
        }

        @ViewBuilder
        private var rowContent: some View {
            HStack {

                VStack(alignment: .leading, spacing: 5) {
                    Text(user.username)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(labelForegroundStyle)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if showServer {
                        Text(server.name)
                            .font(.footnote)
                            .foregroundColor(Color(UIColor.lightGray))
                    }
                }

                Spacer()

                ListRowCheckbox()
            }
        }

        var body: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                userImage
                    .frame(width: 80)
                    .padding(.vertical, 8)
            } content: {
                rowContent
            }
            .onSelect(perform: action)
            .contextMenu {
                Button(L10n.delete, role: .destructive) {
                    onDelete()
                }
            }
        }
    }
}
