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

    struct TimeLimitSection: View {

        @Binding
        var taskTriggerInfo: TaskTriggerInfo

        @State
        var tempTimeLimit: Int?

        // MARK: - Init

        init(taskTriggerInfo: Binding<TaskTriggerInfo>) {
            self._taskTriggerInfo = taskTriggerInfo
            _tempTimeLimit = State(initialValue: taskTriggerInfo.wrappedValue.maxRuntimeTicks)
        }

        // MARK: - Body

        var body: some View {
            Section {
                ChevronInputButton(
                    title: L10n.timeLimit,
                    subtitle: subtitleString,
                    description: L10n.taskTriggerTimeLimit
                ) {
                    TextField(
                        L10n.timeLimit,
                        value: $tempTimeLimit,
                        format: .number
                    )
                    .keyboardType(.numberPad)
                } onSave: {
                    if tempTimeLimit != nil && tempTimeLimit != 0 {
                        taskTriggerInfo.maxRuntimeTicks = ServerTicks(hours: tempTimeLimit).ticks
                    } else {
                        taskTriggerInfo.maxRuntimeTicks = nil
                    }
                } onCancel: {
                    tempTimeLimit = taskTriggerInfo.maxRuntimeTicks
                }
            }
        }

        // MARK: - Create Subtitle String

        private var subtitleString: String {
            if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks {
                ServerTicks(ticks: maxRuntimeTicks).seconds.formatted(.hourMinute)
            } else {
                L10n.disabled
            }
        }
    }
}
