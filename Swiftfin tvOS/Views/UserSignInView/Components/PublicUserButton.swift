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

    struct PublicUserButton: View {

        // MARK: - Environment Variables

        @Environment(\.isEnabled)
        private var isEnabled: Bool

        // MARK: - Public User Variables

        private let user: UserDto
        private let client: JellyfinClient
        private let action: () -> Void

        // MARK: - Initializer

        init(
            user: UserDto,
            client: JellyfinClient,
            action: @escaping () -> Void
        ) {
            self.user = user
            self.client = client
            self.action = action
        }

        // MARK: - Person View

        @ViewBuilder
        private var personView: some View {
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
        }

        // MARK: - Body

        var body: some View {
            Button(action: action) {
                personView
                    .aspectRatio(1, contentMode: .fill)
                    .posterShadow()
                    .clipShape(.circle)
                    .frame(width: 150, height: 150)
                    .hoverEffect(.highlight)

                Text(user.name ?? .emptyDash)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.bottom)
            }
            .buttonBorderShape(.circle)
            .buttonStyle(.borderless)
            .disabled(!isEnabled)
            .foregroundStyle(.primary)
        }
    }
}
