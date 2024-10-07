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

    struct TriggerTypeSection: View {
        @Binding
        var taskTriggerInfo: TaskTriggerInfo
        let allowedTriggerTypes: [TaskTriggerType]

        var body: some View {
            Picker(
                L10n.triggerType,
                selection: Binding<String?>(
                    get: { taskTriggerInfo.type },
                    set: { newValue in
                        if taskTriggerInfo.type != newValue {
                            resetValuesForNewType(newType: newValue)
                        }
                    }
                )
            ) {
                ForEach(allowedTriggerTypes, id: \.rawValue) { type in
                    Text(type.displayTitle).tag(type.rawValue as String?)
                }
            }
            .pickerStyle(.menu)
            .foregroundStyle(.primary)
        }

        private func resetValuesForNewType(newType: String?) {
            taskTriggerInfo.type = newType
            let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks

            switch newType {
            case TaskTriggerType.daily.rawValue:
                taskTriggerInfo.timeOfDayTicks = defaultTimeOfDayTicks()
                taskTriggerInfo.dayOfWeek = nil
                taskTriggerInfo.intervalTicks = nil
            case TaskTriggerType.weekly.rawValue:
                taskTriggerInfo.timeOfDayTicks = defaultTimeOfDayTicks()
                taskTriggerInfo.dayOfWeek = defaultDayOfWeek()
                taskTriggerInfo.intervalTicks = nil
            case TaskTriggerType.interval.rawValue:
                taskTriggerInfo.intervalTicks = defaultIntervalTicks()
                taskTriggerInfo.timeOfDayTicks = nil
                taskTriggerInfo.dayOfWeek = nil
            case TaskTriggerType.startup.rawValue:
                taskTriggerInfo.timeOfDayTicks = nil
                taskTriggerInfo.dayOfWeek = nil
                taskTriggerInfo.intervalTicks = nil
            default:
                taskTriggerInfo.timeOfDayTicks = nil
                taskTriggerInfo.dayOfWeek = nil
                taskTriggerInfo.intervalTicks = nil
            }

            taskTriggerInfo.maxRuntimeTicks = maxRuntimeTicks
        }

        private func defaultTimeOfDayTicks() -> Int {
            0
        }

        private func defaultDayOfWeek() -> DayOfWeek {
            .sunday
        }

        private func defaultIntervalTicks() -> Int {
            Int(3600 * 10_000_000)
        }
    }
}
