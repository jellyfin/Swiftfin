//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension UserSignInView {

    struct PublicUserButton: View {

        let user: UserDto
        let client: JellyfinClient
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                UserProfileImage(
                    userID: user.id,
                    source: user.profileImageSource(
                        client: client,
                        maxWidth: 240
                    )
                )
                .frame(width: 150, height: 150)
                .hoverEffect(.highlight)

                Text(user.name ?? .emptyDash)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .backport
            .buttonBorderShape(.circle)
            .buttonStyle(.borderless)
            .foregroundStyle(.primary, .secondary)
        }
    }
}
