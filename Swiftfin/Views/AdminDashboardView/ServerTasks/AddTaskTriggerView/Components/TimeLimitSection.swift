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

    struct TimeLimitSection: View {

        @Binding
        private var taskTriggerInfo: TaskTriggerInfo

        @State
        private var tempTimeLimit: Int?

        // MARK: - Init

        init(taskTriggerInfo: Binding<TaskTriggerInfo>) {
            self._taskTriggerInfo = taskTriggerInfo
            _tempTimeLimit = State(initialValue: Int(Duration.ticks(taskTriggerInfo.wrappedValue.maxRuntimeTicks ?? 0).hours))
        }

        // MARK: - Body

        var body: some View {
            Section {
                StateAdapter(initialValue: false) { isPresented in
                    ChevronButton(
                        L10n.timeLimit.localizedCapitalized,
                        content: subtitleString
                    ) {
                        isPresented.wrappedValue = true
                    }
                    .alert(L10n.timeLimit.localizedCapitalized, isPresented: isPresented) {
                        TextField(
                            L10n.hours,
                            value: $tempTimeLimit,
                            format: .number
                        )
                        .keyboardType(.numberPad)

                        Button(L10n.save) {
                            if tempTimeLimit != nil && tempTimeLimit != 0 {
                                taskTriggerInfo.maxRuntimeTicks = Duration.hours(tempTimeLimit ?? 0).ticks
                            } else {
                                taskTriggerInfo.maxRuntimeTicks = nil
                            }
                        }

                        Button(L10n.cancel, role: .cancel) {
                            if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks {
                                tempTimeLimit = Int(Duration.ticks(maxRuntimeTicks).hours)
                            } else {
                                tempTimeLimit = nil
                            }
                        }
                    } message: {
                        Text(L10n.taskTriggerTimeLimit)
                    }
                }
            }
        }

        // MARK: - Create Subtitle String

        private var subtitleString: String {
            if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks {
                Duration.ticks(maxRuntimeTicks).formatted(.hourMinuteAbbreviated)
            } else {
                L10n.none
            }
        }
    }
}
