//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension UserSignInView {

    struct PublicUserRow: View {

        @Environment(\.colorScheme)
        private var colorScheme

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

                        UserProfileImage(
                            userID: user.id,
                            source: user.profileImageSource(
                                client: client,
                                maxWidth: 120
                            )
                        )
                    }
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
            .foregroundStyle(.primary)
        }
    }
}
