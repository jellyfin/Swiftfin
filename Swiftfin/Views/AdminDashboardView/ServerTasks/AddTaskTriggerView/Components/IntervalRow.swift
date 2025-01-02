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

    struct IntervalRow: View {

        @Binding
        private var taskTriggerInfo: TaskTriggerInfo

        @State
        private var tempInterval: Int?

        // MARK: - Init

        init(taskTriggerInfo: Binding<TaskTriggerInfo>) {
            self._taskTriggerInfo = taskTriggerInfo
            _tempInterval = State(initialValue: Int(ServerTicks(taskTriggerInfo.wrappedValue.intervalTicks).minutes))
        }

        // MARK: - Body

        var body: some View {
            ChevronAlertButton(
                L10n.every,
                subtitle: ServerTicks(
                    taskTriggerInfo.intervalTicks
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
                    tempInterval = Int(ServerTicks(intervalTicks).minutes)
                } else {
                    tempInterval = nil
                }
            }
        }
    }
}
