//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Stinsen
import SwiftUI

extension EditScheduledTaskView {

    struct TriggerRow: View {

        let taskTriggerInfo: TaskTriggerInfo

        // TODO: remove after `TaskTriggerType` is provided by SDK
        private var taskTriggerType: TaskTriggerType {
            if let type = taskTriggerInfo.type {
                return TaskTriggerType(rawValue: type)!
            } else {
                return .startup
            }
        }

        // MARK: - Body

        var body: some View {
            VStack(alignment: .leading) {

                Text(triggerDisplayText)
                    .fontWeight(.semibold)

                Group {
                    if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks {
                        Text(
                            L10n.timeLimitLabelWithHours(
                                timeIntervalFromTicks(maxRuntimeTicks).formatted(.hourMinute)
                            )
                        )
                    } else {
                        Text("No runtime limit")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        // MARK: - Trigger Display Text

        private var triggerDisplayText: String {
            switch taskTriggerType {
            case .daily:
                if let timeOfDayTicks = taskTriggerInfo.timeOfDayTicks {
                    return L10n.itemAtItem(
                        taskTriggerType.displayTitle,
                        timeFromTicks(timeOfDayTicks).formatted(date: .omitted, time: .shortened)
                    )
                }
            case .weekly:
                if let dayOfWeek = taskTriggerInfo.dayOfWeek,
                   let timeOfDayTicks = taskTriggerInfo.timeOfDayTicks
                {
                    return L10n.itemAtItem(
                        dayOfWeek.rawValue.capitalized,
                        timeFromTicks(timeOfDayTicks).formatted(date: .omitted, time: .shortened)
                    )
                }
            case .interval:
                if let intervalTicks = taskTriggerInfo.intervalTicks {
                    return L10n.everyInterval(
                        timeIntervalFromTicks(intervalTicks).formatted(.hourMinute)
                    )
                }
            case .startup:
                return taskTriggerType.displayTitle
            }

            return L10n.unknown
        }

        // MARK: - Convert Ticks to TimeInterval

        private func timeIntervalFromTicks(_ ticks: Int) -> TimeInterval {
            TimeInterval(ticks) / 10_000_000
        }

        // MARK: - Convert Ticks to Time

        private func timeFromTicks(_ ticks: Int) -> Date {
            let totalSeconds = timeIntervalFromTicks(ticks)
            let hours = Int(totalSeconds) / 3600
            let minutes = (Int(totalSeconds) % 3600) / 60
            var components = DateComponents()
            components.hour = hours
            components.minute = minutes
            return Calendar.current.date(from: components) ?? Date()
        }
    }
}
