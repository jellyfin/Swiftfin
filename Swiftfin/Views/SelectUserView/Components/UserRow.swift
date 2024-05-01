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

        let user: UserState
        let server: ServerState
        var onSelect: () -> Void

        private var personView: some View {
            SystemImageContentView(systemName: "person.fill", ratio: 0.5)
        }

        @ViewBuilder
        private var userImage: some View {
            ZStack {
                Color.clear

                ImageView(user.profileImageSource(client: server.client, maxWidth: 120, maxHeight: 120))
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
                    onSelect()
                } label: {
                    ZStack {
                        Color.clear

                        HStack(alignment: .center, spacing: EdgeInsets.edgePadding) {

                            userImage
                                .frame(width: 80)
                                .padding(.vertical, 8)

                            HStack {

                                Text(user.username)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

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

                Color.secondarySystemFill
                    .frame(width: contentSize.width, height: 1)
            }
        }
    }
}
