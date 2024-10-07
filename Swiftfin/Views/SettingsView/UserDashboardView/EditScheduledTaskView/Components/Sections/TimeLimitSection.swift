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
                    loadInitialValue()
                }
                .alert(L10n.timeLimit, isPresented: $isPresentingTimeLimitAlert) {
                    TextField(
                        L10n.timeLimit,
                        value: $inputValue,
                        format: .number
                    )
                    .keyboardType(.numberPad)

                    Button(L10n.save) {
                        saveTimeLimit()
                    }
                    Button(L10n.cancel, role: .cancel) {
                        isPresentingTimeLimitAlert = false
                    }
                } message: {
                    Text(L10n.timeLimit)
                }
            }
        }

        private var timeLimitSubtitle: Text {
            if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks, maxRuntimeTicks > 0 {
                let timeInterval = TimeInterval(maxRuntimeTicks) / 10_000_000
                return Text(timeInterval.formatted(.hourMinute))
            } else {
                return Text(L10n.disabled)
            }
        }

        private func loadInitialValue() {
            if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks {
                inputValue = maxRuntimeTicks / (10_000_000 * 3600)
            } else {
                inputValue = 0
            }
        }

        private func saveTimeLimit() {
            if inputValue > 0 {
                taskTriggerInfo.maxRuntimeTicks = inputValue * 10_000_000 * 3600
            } else {
                taskTriggerInfo.maxRuntimeTicks = nil
            }
            isPresentingTimeLimitAlert = false
        }
    }
}
