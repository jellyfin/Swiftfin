//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension UserSignInView {

    struct PublicUserButton: View {

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

        var body: some View {
            Button {
                action()
            } label: {
                HStack {
                    ZStack {
                        Color.clear

                        ImageView(user.profileImageSource(client: client, maxWidth: 120, maxHeight: 120))
                            .placeholder { _ in
                                SystemImageContentView(systemName: "person.fill", ratio: 0.5)
                            }
                            .failure {
                                SystemImageContentView(systemName: "person.fill", ratio: 0.5)
                            }
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .posterShadow()
                    .posterBorder(ratio: 1 / 2, of: \.width)
                    .clipShape(.circle)
                    .frame(width: 50, height: 50)

                    Text(user.name ?? .emptyDash)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.body.weight(.regular))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
