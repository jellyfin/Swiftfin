//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AdminDashboardView {

    struct UserSection: View {

        @CurrentDate
        private var currentDate: Date

        let user: UserDto
        let lastActivityDate: Date?
        let action: (() -> Void)?

        var body: some View {
            Section(L10n.user) {

                if let action {
                    SettingsView.UserProfileRow(
                        user: user,
                        action: action
                    )
                } else {
                    SettingsView.UserProfileRow(
                        user: user
                    )
                }

                LabeledContent(L10n.lastSeen, value: lastActivityDate, format: .lastSeen)
                    .id(currentDate)
                    .monospacedDigit()
            }
        }
    }
}
