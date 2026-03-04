//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension SelectUserView {

    struct GridUserButton: PlatformView {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isEnabled)
        private var isEnabled
        @Environment(\.isSelected)
        private var isSelected

        private let item: UserItem?
        private let showServer: Bool
        private let action: () -> Void
        private let onDelete: (() -> Void)?

        private var isAddUser: Bool {
            item == nil
        }

        private var labelForegroundStyle: HierarchicalShapeStyle {
            if isAddUser {
                return isEnabled ? .primary : .secondary
            }
            guard isEditing else {
                return .primary
            }
            return isSelected ? .primary : .secondary
        }

        var iOSView: some View {
            Button(action: action) {
                VStack {
                    imageContent
                    titleContent
                    serverContent
                }
            }
            .if(!isEditing) { button in
                button
                    .contextMenu {
                        Button(
                            L10n.delete,
                            role: .destructive,
                            action: onDelete ?? {}
                        )
                    }
            }
            .buttonStyle(.plain)
        }

        var tvOSView: some View {
            // Hover Effects break in the normal button
            if isAddUser {
                imageContent
                titleContent
                serverContent
            } else {
                Button(action: action) {
                    imageContent
                    titleContent
                    serverContent
                }
                .if(!isEditing) { button in
                    button
                        .contextMenu {
                            Button(
                                L10n.delete,
                                role: .destructive,
                                action: onDelete ?? {}
                            )
                        }
                }
                .buttonStyle(.borderless)
                .backport
                .buttonBorderShape(.circle)
                .foregroundStyle(.primary, .secondary)
            }
        }

        @ViewBuilder
        private var imageContent: some View {
            UserButtonImage(item)
                .hoverEffect(.highlight)
                .overlay(alignment: .bottomTrailing) {
                    if !isAddUser, isEditing, isSelected {
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
        }

        @ViewBuilder
        private var titleContent: some View {
            Text(item?.user.username ?? L10n.addUser)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(labelForegroundStyle)
                .lineLimit(1)
        }

        @ViewBuilder
        private var serverContent: some View {
            if showServer {
                if let item {
                    Text(item.server.name)
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                } else {
                    // For layout, not to be localized
                    Text("Hidden")
                        .font(.footnote)
                        .hidden()
                }
            }
        }
    }
}

extension SelectUserView.GridUserButton {

    // Add New User
    init(
        action: @escaping () -> Void
    ) {
        self.item = nil
        self.showServer = false
        self.action = action
        self.onDelete = nil
    }

    // Local User
    init(
        user: UserState,
        server: ServerState,
        showServer: Bool,
        action: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.item = (user: user, server: server)
        self.showServer = showServer
        self.action = action
        self.onDelete = onDelete
    }
}
