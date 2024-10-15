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

    struct CurrentRunningSection: View {

        var task: TaskInfo

        var body: some View {
            Section(L10n.progress) {
                if let status = task.state {
                    TextPairView(L10n.status, value: Text(status.displayTitle))
                }

                if let currentProgressPercentage = task.currentProgressPercentage {
                    TextPairView(
                        L10n.taskCompleted,
                        value: Text("\(currentProgressPercentage / 100, format: .percent.precision(.fractionLength(1)))")
                    )
                    .monospacedDigit()
                }
            }
        }
    }
}
