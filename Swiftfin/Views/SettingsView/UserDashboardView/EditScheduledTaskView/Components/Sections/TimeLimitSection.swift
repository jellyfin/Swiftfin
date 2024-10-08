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
        private var isPresentingTimeLimitAlert = false
        @State
        private var inputValue: Int = 0

        var body: some View {
            Section {
                ChevronButton(
                    L10n.timeLimit,
                    subtitle: timeLimitSubtitle
                )
                .onSelect {
                    isPresentingTimeLimitAlert = true
                    inputValue = hoursFromTicks(taskTriggerInfo.maxRuntimeTicks)
                }
                .alert(L10n.timeLimit, isPresented: $isPresentingTimeLimitAlert) {
                    TextField(
                        L10n.timeLimit,
                        value: $inputValue,
                        format: .number
                    )
                    .keyboardType(.numberPad)

                    Button(L10n.save) {
                        taskTriggerInfo.maxRuntimeTicks = ticksFromHours(inputValue)
                        isPresentingTimeLimitAlert = false
                    }
                    Button(L10n.cancel, role: .cancel) {
                        isPresentingTimeLimitAlert = false
                    }
                }
            }
        }

        private var timeLimitSubtitle: Text {
            if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks, maxRuntimeTicks > 0 {
                return Text(timeFromTicks(maxRuntimeTicks))
            } else {
                return Text(L10n.disabled)
            }
        }

        private func hoursFromTicks(_ ticks: Int?) -> Int {
            guard let ticks = ticks else { return 0 }
            return ticks / 36_000_000_000
        }

        private func ticksFromHours(_ hours: Int) -> Int? {
            hours > 0 ? hours * 36_000_000_000 : nil
        }

        private func timeFromTicks(_ ticks: Int) -> String {
            let timeInterval = TimeInterval(ticks) / 10_000_000
            return timeInterval.formatted(.hourMinute)
        }
    }
}
