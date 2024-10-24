//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension UserDashboardView {

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

                if let lastActivityDate {
                    let timeInterval = currentDate.timeIntervalSince(lastActivityDate)
                    let twentyFourHours: TimeInterval = 24 * 60 * 60

                    TextPairView(
                        L10n.lastSeen,
                        value: timeInterval <= twentyFourHours ?
                            Text(lastActivityDate, format: .relative(presentation: .numeric, unitsStyle: .narrow)) :
                            Text(lastActivityDate, style: .date)
                    )
                    .id(currentDate)
                    .monospacedDigit()
                } else {
                    TextPairView(
                        L10n.lastSeen,
                        value: Text(L10n.never)
                    )
                }
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
