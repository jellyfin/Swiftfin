//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AddTaskTriggerView {

    struct TriggerTypeRow: View {

        @Binding
        var taskTriggerInfo: TaskTriggerInfo

        var body: some View {
            Picker(
                L10n.type,
                selection: Binding<TaskTriggerType?>(
                    get: {
                        if let t = taskTriggerInfo.type {
                            return TaskTriggerType(rawValue: t)
                        } else {
                            return nil
                        }
                    },
                    set: { newValue in
                        if taskTriggerInfo.type != newValue?.rawValue {
                            resetValuesForNewType(newType: newValue)
                        }
                    }
                )
            ) {
                ForEach(TaskTriggerType.allCases, id: \.self) { type in
                    Text(type.displayTitle)
                        .tag(type as TaskTriggerType?)
                }
            }
        }

        private func resetValuesForNewType(newType: TaskTriggerType?) {
            taskTriggerInfo.type = newType?.rawValue
            let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks

            switch newType {
            case .daily:
                taskTriggerInfo.timeOfDayTicks = defaultTimeOfDayTicks
                taskTriggerInfo.dayOfWeek = nil
                taskTriggerInfo.intervalTicks = nil
            case .weekly:
                taskTriggerInfo.timeOfDayTicks = defaultTimeOfDayTicks
                taskTriggerInfo.dayOfWeek = defaultDayOfWeek
                taskTriggerInfo.intervalTicks = nil
            case .interval:
                taskTriggerInfo.intervalTicks = defaultIntervalTicks
                taskTriggerInfo.timeOfDayTicks = nil
                taskTriggerInfo.dayOfWeek = nil
            case .startup:
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
    }
}
