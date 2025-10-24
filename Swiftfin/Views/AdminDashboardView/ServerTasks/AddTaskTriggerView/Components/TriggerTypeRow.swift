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
                selection: $taskTriggerInfo.type
            ) {
                ForEach(TaskTriggerInfoType.allCases, id: \.self) { type in
                    Text(type.displayTitle)
                        .tag(type as TaskTriggerInfoType?)
                }
            }
            .onChange(of: taskTriggerInfo.type) { newType in
                resetValuesForNewType(newType: newType)
            }
        }

        private func resetValuesForNewType(newType: TaskTriggerInfoType?) {
            taskTriggerInfo.type = newType
            let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks

            switch newType {
            case .dailyTrigger:
                taskTriggerInfo.timeOfDayTicks = defaultTimeOfDayTicks
                taskTriggerInfo.dayOfWeek = nil
                taskTriggerInfo.intervalTicks = nil
            case .weeklyTrigger:
                taskTriggerInfo.timeOfDayTicks = defaultTimeOfDayTicks
                taskTriggerInfo.dayOfWeek = defaultDayOfWeek
                taskTriggerInfo.intervalTicks = nil
            case .intervalTrigger:
                taskTriggerInfo.intervalTicks = defaultIntervalTicks
                taskTriggerInfo.timeOfDayTicks = nil
                taskTriggerInfo.dayOfWeek = nil
            case .startupTrigger:
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
