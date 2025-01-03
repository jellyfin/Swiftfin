//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AdminDashboardView {

    struct UserSection: View {

        @CurrentDate
        private var currentDate: Date

        private let user: UserDto
        private let lastActivityDate: Date?
        private let action: (() -> Void)?

        // MARK: - Initializer

        init(user: UserDto, lastActivityDate: Date? = nil, action: (() -> Void)? = nil) {
            self.user = user
            self.lastActivityDate = lastActivityDate
            self.action = action
        }

        // MARK: - Body

        var body: some View {
            Section(L10n.user) {
                profileView
                TextPairView(
                    L10n.lastSeen,
                    value: Text(lastActivityDate, format: .lastSeen)
                )
                .id(currentDate)
                .monospacedDigit()
            }
        }

        // MARK: - Profile View

        private var profileView: some View {
            if let onSelect = action {
                SettingsView.UserProfileRow(
                    user: user
                ) {
                    onSelect()
                }
            } else {
                SettingsView.UserProfileRow(
                    user: user
                )
            }
        }
    }
}
