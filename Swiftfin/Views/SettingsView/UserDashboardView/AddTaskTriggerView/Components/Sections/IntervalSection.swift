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

        @State
        var tempInterval: Int?

        // MARK: - Body

        var body: some View {
            if taskTriggerInfo.type == TaskTriggerType.interval.rawValue {
                ChevronAlertButton(
                    L10n.every,
                    subtitle: ServerTicks(
                        ticks: taskTriggerInfo.intervalTicks
                    ).seconds.formatted(.hourMinute),
                    description: L10n.taskTriggerInterval
                ) {
                    TextField(
                        L10n.minutes,
                        value: $tempInterval,
                        format: .number
                    )
                    .keyboardType(.numberPad)
                } onSave: {
                    if tempInterval != nil && tempInterval != 0 {
                        taskTriggerInfo.intervalTicks = ServerTicks(minutes: tempInterval).ticks
                    } else {
                        taskTriggerInfo.intervalTicks = nil
                    }
                } onCancel: {
                    if let intervalTicks = taskTriggerInfo.intervalTicks {
                        tempInterval = Int(ServerTicks(minutes: intervalTicks).minutes)
                    } else {
                        taskTriggerInfo.intervalTicks = nil
                    }
                }
            }
        }
    }
}
