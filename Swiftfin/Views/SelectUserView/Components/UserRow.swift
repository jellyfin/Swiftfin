//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension SelectUserView {

    struct UserRow: View {

        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isSelected)
        private var isSelected

        @State
        private var contentSize: CGSize = .zero

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

        private var personView: some View {
            ZStack {
                Color.tertiarySystemBackground

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

                ImageView(user.profileImageSource(client: server.client, maxWidth: 120))
                    .image { image in
                        image
                            .posterBorder(ratio: 1 / 2, of: \.width)
                    }
                    .placeholder { _ in
                        personView
                    }
                    .failure {
                        personView
                    }

                if isEditing {
                    Color.black
                        .opacity(isSelected ? 0 : 0.5)
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .clipShape(.circle)
        }

        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                Button {
                    action()
                } label: {
                    ZStack {
                        Color.clear

                        HStack(alignment: .center, spacing: EdgeInsets.edgePadding) {

                            userImage
                                .frame(width: 80)
                                .padding(.vertical, 8)

                            HStack {

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(user.username)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(labelForegroundStyle)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)

                                    if showServer {
                                        Text(server.name)
                                            .font(.caption)
                                            .foregroundColor(Color(UIColor.lightGray))
                                    }
                                }

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                        .paletteOverlayRendering()
                                } else if isEditing {
                                    Image(systemName: "circle")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .trackingSize($contentSize)
                        }
                    }
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                }

                Color.secondarySystemFill
                    .frame(width: contentSize.width, height: 1)
            }
        }
    }
}
