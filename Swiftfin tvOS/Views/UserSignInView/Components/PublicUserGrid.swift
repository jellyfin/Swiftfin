//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: change from list to grid button

extension UserSignInView {

    struct PublicUserGrid: View {

        private let user: UserDto
        private let client: JellyfinClient
        private let action: () -> Void

        init(
            user: UserDto,
            client: JellyfinClient,
            action: @escaping () -> Void
        ) {
            self.user = user
            self.client = client
            self.action = action
        }

        @ViewBuilder
        private var personView: some View {
            RelativeSystemImageView(systemName: "person.fill", ratio: 0.5)
                .foregroundStyle(.secondary)
                .clipShape(.circle)
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 100, height: 100)
        }

        var body: some View {
            Button {
                action()
            } label: {
                VStack {
                    ImageView(user.profileImageSource(client: client))
                        .image { image in
                            image
                                .posterBorder(ratio: 0.5, of: \.width)
                        }
                        .placeholder { _ in
                            personView
                        }
                        .failure {
                            personView
                        }
                        .aspectRatio(1, contentMode: .fill)
                        .clipShape(.circle)
                        .frame(width: 100, height: 100)

                    Text(user.name ?? .emptyDash)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            // .buttonStyle(.card)
            .foregroundStyle(.primary)
        }
    }
}
