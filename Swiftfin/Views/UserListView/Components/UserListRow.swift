//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension UserListView {

    struct UserListRow: View {

        @Environment(\.isEditing)
        private var isEditing: Bool
        @Environment(\.isSelected)
        private var isSelected: Bool

        @State
        private var contentSize: CGSize = .zero

        let user: UserState
        let server: ServerState
        var onSelect: () -> Void

        private var personView: some View {
            SystemImageContentView(systemName: "person.fill")
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
            .cornerRadius(ratio: 1 / 30, of: \.width)
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

// extension UserListView.UserListRow {
//
//    init(user: UserState, server: ServerState) {
//        self.init(
//            server: server,
//            user: user,
//            onSelect: {}
//        )
//    }
//
//    func onSelect(_ action: @escaping () -> Void) -> Self {
//        copy(modifying: \.onSelect, with: action)
//    }
// }
