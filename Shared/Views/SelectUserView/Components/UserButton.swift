//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension SelectUserView {

    struct UserButton: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isSelected)
        private var isSelected

        private let displayType: LibraryDisplayType
        private let user: UserState
        private let server: ServerState
        private let showServer: Bool
        private let action: () -> Void
        private let onDelete: () -> Void

        init(
            displayType: LibraryDisplayType,
            user: UserState,
            server: ServerState,
            showServer: Bool,
            action: @escaping () -> Void,
            onDelete: @escaping () -> Void
        ) {
            self.displayType = displayType
            self.user = user
            self.server = server
            self.showServer = showServer
            self.action = action
            self.onDelete = onDelete
        }

        private var labelForegroundStyle: some ShapeStyle {
            guard isEditing else {
                return .primary
            }

            return isSelected ? .primary : .secondary
        }

        @ViewBuilder
        private var profileImage: some View {
            UserProfileImage(
                userID: user.id,
                source: user.profileImageSource(
                    client: server.client
                ),
                pipeline: .Swiftfin.local
            )
        }

        @ViewBuilder
        private var gridView: some View {
            Button(action: action) {
                VStack {
                    profileImage
                        .hoverEffect(.highlight)
                        .overlay(alignment: .bottomTrailing) {
                            if isEditing, isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(
                                        width: UIDevice.isTV ? 75 : 40,
                                        height: UIDevice.isTV ? 75 : 40
                                    )
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(accentColor.overlayColor, accentColor)
                                    .hoverEffect(.lift)
                            }
                        }

                    Text(user.username)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(labelForegroundStyle)
                        .lineLimit(1)

                    if showServer {
                        Text(server.name)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .contextMenu {
                if !isEditing {
                    Button(
                        L10n.delete,
                        role: .destructive,
                        action: onDelete
                    )
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
        private var listView: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                profileImage
                    .frame(width: 80)
                    .padding(.vertical, 8)
            } content: {
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
            .onSelect(perform: action)
            .contextMenu {
                if !isEditing {
                    Button(
                        L10n.delete,
                        role: .destructive,
                        action: onDelete
                    )
                }
            }
        }

        var body: some View {
            switch (displayType, UIDevice.isTV) {
            case (.list, false):
                listView
            default:
                gridView
            }
        }
    }
}
