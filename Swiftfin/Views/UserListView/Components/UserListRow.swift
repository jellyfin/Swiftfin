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

        @State
        private var contentSize: CGSize = .zero

        private let client: JellyfinClient
        private let user: UserDto
        private var onSelect: () -> Void

        private var personView: some View {
            SystemImageContentView(systemName: "person.fill")
        }

        @ViewBuilder
        private var userImage: some View {
            ZStack {
                Color.clear

                ImageView(user.profileImageSource(client: client, maxWidth: 120, maxHeight: 120))
                    .placeholder { _ in
                        personView
                    }
                    .failure {
                        personView
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
                    HStack(alignment: .center, spacing: EdgeInsets.edgePadding) {

                        userImage
                            .frame(width: 80)
                            .padding(.vertical, 8)

                        HStack {

                            Text(user.name ?? .emptyDash)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .trackingSize($contentSize)
                    }
                }
                .buttonStyle(.plain)

                Color.secondarySystemFill
                    .frame(width: contentSize.width, height: 1)
            }
        }
    }
}

extension UserListView.UserListRow {

    init(user: UserDto, client: JellyfinClient) {
        self.init(
            client: client,
            user: user,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
