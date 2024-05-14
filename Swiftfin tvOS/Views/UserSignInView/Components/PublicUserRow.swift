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

    struct PublicUserRow: View {

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

        private var personView: some View {
            ZStack {
                Color.secondarySystemFill

                RelativeSystemImageView(systemName: "person.fill", ratio: 0.5)
                    .foregroundStyle(.secondary)
            }
            .clipShape(.circle)
            .aspectRatio(1, contentMode: .fill)
        }

        var body: some View {
            Button {
                action()
            } label: {
                HStack {
                    ZStack {
                        Color.clear

                        ImageView(user.profileImageSource(client: client, maxWidth: 120))
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
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .posterShadow()
                    .clipShape(.circle)
                    .frame(width: 50, height: 50)

                    Text(user.name ?? .emptyDash)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()
                }
            }
            .buttonStyle(.card)
            .foregroundStyle(.primary)
        }
    }
}
