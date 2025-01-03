//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

extension SettingsView {

    struct UserProfileRow: View {

        @Injected(\.currentUserSession)
        private var userSession: UserSession!

        private let user: UserDto
        private let action: (() -> Void)?

        var body: some View {
            Button {
                guard let action else { return }
                action()
            } label: {
                HStack {

                    // `.aspectRatio(contentMode: .fill)` on `imageView` alone
                    // causes a crash on some iOS versions
                    ZStack {
                        UserProfileImage(
                            userID: user.id,
                            source: user.profileImageSource(
                                client: userSession.client,
                                maxWidth: 120
                            )
                        )
                    }
                    .frame(width: 50, height: 50)

                    Text(user.name ?? L10n.unknown)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Spacer()

                    if action != nil {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.regular))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .foregroundStyle(.primary, .secondary)
        }
    }
}

extension SettingsView.UserProfileRow {

    init(user: UserDto) {
        self.init(
            user: user,
            action: nil
        )
    }

    init(user: UserDto, perform action: @escaping () -> Void) {
        self.init(
            user: user,
            action: action
        )
    }
}
