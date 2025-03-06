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

        var body: some View {
            Button {
                action()
            } label: {
                VStack(alignment: .center) {
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
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(.circle)
                    .overlay {
                        if isEditing {
                            ZStack(alignment: .bottomTrailing) {
                                Color.black
                                    .opacity(isSelected ? 0 : 0.5)
                                    .clipShape(.circle)

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40, alignment: .bottomTrailing)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(accentColor.overlayColor, accentColor)
                                }
                            }
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
            .buttonStyle(.plain)
            .contextMenu {
                Button(L10n.delete, role: .destructive) {
                    onDelete()
                }
            }
        }
    }
}
