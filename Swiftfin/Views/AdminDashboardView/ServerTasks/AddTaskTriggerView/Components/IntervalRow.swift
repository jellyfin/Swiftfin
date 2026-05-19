//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import JellyfinAPI
import SwiftUI

extension AddTaskTriggerView {

    struct IntervalRow: View {

        @Binding
        private var taskTriggerInfo: TaskTriggerInfo

        @State
        private var tempInterval: Duration?

        // MARK: - Init

        init(taskTriggerInfo: Binding<TaskTriggerInfo>) {
            self._taskTriggerInfo = taskTriggerInfo
            tempInterval = Duration.ticks(taskTriggerInfo.wrappedValue.intervalTicks ?? 0)
        }

        // MARK: - Body

        var body: some View {
            StateAdapter(initialValue: false) { isPresented in
                ChevronButton(
                    L10n.every,
                    content: Text(Duration.ticks(taskTriggerInfo.intervalTicks ?? 0), format: .hourMinuteAbbreviated)
                ) {
                    isPresented.wrappedValue = true
                }
                .alert(L10n.every, isPresented: isPresented) {
                    TextField(
                        L10n.minutes,
                        value: $tempInterval.map(
                            getter: { $0.map { Int($0.minutes) } },
                            setter: { Duration.minutes($0 ?? 0) }
                        ),
                        format: .number
                    )
                    .keyboardType(.numberPad)

                    Button(L10n.save) {
                        if let tempInterval, tempInterval != .zero {
                            taskTriggerInfo.intervalTicks = tempInterval.ticks
                        } else {
                            taskTriggerInfo.intervalTicks = nil
                        }
                    }

                    Button(L10n.cancel, role: .cancel) {
                        if let existingIntervalTicks = taskTriggerInfo.intervalTicks {
                            tempInterval = Duration.ticks(existingIntervalTicks)
                        } else {
                            tempInterval = nil
                        }
                    }
                } message: {
                    Text(L10n.taskTriggerInterval)
                }
            }
        }
    }
}
