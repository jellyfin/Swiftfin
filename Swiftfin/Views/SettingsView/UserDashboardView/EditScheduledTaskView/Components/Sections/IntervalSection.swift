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

        private let defaultIntervalTicks = 36_000_000_000

        var body: some View {
            if taskTriggerInfo.type == TaskTriggerType.interval.rawValue {
                Picker(
                    L10n.every,
                    selection: Binding(
                        get: { taskTriggerInfo.intervalTicks ?? defaultIntervalTicks },
                        set: { taskTriggerInfo.intervalTicks = $0 }
                    )
                ) {
                    ForEach(TaskTriggerInterval.allCases) { interval in
                        Text(interval.displayTitle).tag(Int(interval.rawValue))
                    }
                }
                .pickerStyle(.menu)
                .foregroundStyle(.primary)
            }
        }
    }
}
