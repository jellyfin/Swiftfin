//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: if lastActivityDate not in same day, use date instead of relative

extension UserDashboardView {

    struct UserSection: View {

        @CurrentDate
        private var currentDate: Date

        private let user: UserDto
        private let lastActivityDate: Date?

        init(user: UserDto, lastActivityDate: Date? = nil) {
            self.user = user
            self.lastActivityDate = lastActivityDate
        }

        var body: some View {
            Section(L10n.user) {
                SettingsView.UserProfileRow(
                    user: user
                )

                if let lastActivityDate {
                    TextPairView(
                        L10n.lastSeen,
                        value: Text(lastActivityDate, format: .relative(presentation: .numeric, unitsStyle: .narrow))
                    )
                    .id(currentDate)
                    .monospacedDigit()
                }
            }
        }
    }
}
