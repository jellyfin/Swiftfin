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

        // MARK: - Body

        var body: some View {
            Section {
                ChevronInputButton(
                    title: L10n.timeLimit,
                    subtitle: subtitleString,
                    description: L10n.taskTriggerTimeLimit,
                    helpText: L10n.hours,
                    value: Binding(
                        get: {
                            Int(ServerTicks(ticks: taskTriggerInfo.maxRuntimeTicks).hours)
                        },
                        set: {
                            taskTriggerInfo.maxRuntimeTicks = ServerTicks(hours: $0).ticks
                        }
                    ),
                    keyboard: .numberPad
                )
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
