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

    struct TimeSection: View {

        @Binding
        var taskTriggerInfo: TaskTriggerInfo

        private let defaultTimeOfDayTicks = 0

        var body: some View {
            if taskTriggerInfo.type == TaskTriggerType.daily.rawValue || taskTriggerInfo.type == TaskTriggerType.weekly.rawValue {
                DatePicker(
                    L10n.time,
                    selection: Binding<Date>(
                        get: {
                            dateFromTimeOfDayTicks(taskTriggerInfo.timeOfDayTicks ?? defaultTimeOfDayTicks)
                        },
                        set: { date in
                            taskTriggerInfo.timeOfDayTicks = timeOfDayTicksFromDate(date)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        }

        private func dateFromTimeOfDayTicks(_ ticks: Int) -> Date {
            let totalSeconds = TimeInterval(ticks) / 10_000_000
            let hours = Int(totalSeconds) / 3600
            let minutes = (Int(totalSeconds) % 3600) / 60
            var components = DateComponents()
            components.hour = hours
            components.minute = minutes
            return Calendar.current.date(from: components) ?? Date()
        }

        private func timeOfDayTicksFromDate(_ date: Date) -> Int {
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            let totalSeconds = TimeInterval((components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60)
            return Int(totalSeconds * 10_000_000)
        }
    }
}
