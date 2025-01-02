//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension EditServerTaskView {

    struct LastRunSection: View {

        @CurrentDate
        private var currentDate: Date

        let status: TaskCompletionStatus
        let endTime: Date

        var body: some View {
            Section(L10n.lastRun) {

                TextPairView(
                    leading: L10n.status,
                    trailing: status.displayTitle
                )

                TextPairView(
                    L10n.executed,
                    value: Text(endTime, format: .lastSeen)
                )
                .id(currentDate)
                .monospacedDigit()
            }
        }
    }
}
