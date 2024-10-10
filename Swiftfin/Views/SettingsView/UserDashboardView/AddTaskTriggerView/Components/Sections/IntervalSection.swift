//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AddTaskTriggerView {

    struct IntervalSection: View {

        @Binding
        var taskTriggerInfo: TaskTriggerInfo

        // MARK: - Body

        var body: some View {
            if taskTriggerInfo.type == TaskTriggerType.interval.rawValue {
                Picker(
                    L10n.every,
                    selection: Binding(
                        get: { taskTriggerInfo.intervalTicks ?? defaultIntervalTicks },
                        set: { taskTriggerInfo.intervalTicks = $0 }
                    )
                ) {
                    ForEach(Array(stride(from: 900, to: 86400 + 1, by: 900)), id: \.self) { interval in
                        Text(TimeInterval(interval).formatted(.hourMinute)).tag(ServerTicks(seconds: interval).ticks)
                    }
                }
            }
        }
    }
}
