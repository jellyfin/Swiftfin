//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension EditScheduledTaskView {

    struct LastRunSection: View {

        var lastExecutionResult: TaskResult

        var body: some View {
            Section(L10n.lastRun) {
                if let status = lastExecutionResult.status {
                    TextPairView(L10n.status, value: Text(status.displayTitle))
                }
                if let endTimeUtc = lastExecutionResult.endTimeUtc {
                    TextPairView(
                        L10n.executed,
                        value: Text("\(endTimeUtc, format: .relative(presentation: .numeric, unitsStyle: .narrow))")
                    )
                    .monospacedDigit()
                }
            }
        }
    }
}
