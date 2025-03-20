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

    struct UserGridButton: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isSelected)
        private var isSelected

        private let user: UserState
        private let server: ServerState
        private let showServer: Bool
        private let action: () -> Void
        private let onDelete: () -> Void

        // MARK: - Initializer

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

        // MARK: - Label Foreground Style

        private var labelForegroundStyle: some ShapeStyle {
            guard isEditing else { return .primary }

            return isSelected ? .primary : .secondary
        }

        // MARK: - User Portrait

        private var userPortrait: some View {
            UserProfileImage(
                userID: user.id,
                source: user.profileImageSource(
                    client: server.client,
                    maxWidth: 120
                ),
                pipeline: .Swiftfin.local
            )
            .aspectRatio(1, contentMode: .fill)
            .clipShape(.circle)
            .overlay {
                if isEditing {
                    ZStack(alignment: .bottom) {
                        Color.black
                            .opacity(isSelected ? 0 : 0.5)

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 75, height: 75)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(accentColor.overlayColor, accentColor)
                        }
                    }
                }
            }
        }

        // MARK: - Body

        var body: some View {
            VStack {
                Button {
                    action()
                } label: {
                    userPortrait
                        .hoverEffect(.highlight)

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
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
                .contextMenu {
                    Button(L10n.delete, role: .destructive) {
                        onDelete()
                    }
                }
            }
        }
    }
}
