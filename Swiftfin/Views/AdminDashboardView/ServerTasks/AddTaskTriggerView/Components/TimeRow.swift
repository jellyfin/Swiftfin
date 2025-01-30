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

    struct TimeRow: View {

        @Binding
        var taskTriggerInfo: TaskTriggerInfo

        var body: some View {
            DatePicker(
                L10n.time,
                selection: Binding<Date>(
                    get: {
                        ServerTicks(
                            taskTriggerInfo.timeOfDayTicks ?? defaultTimeOfDayTicks
                        ).date
                    },
                    set: { date in
                        taskTriggerInfo.timeOfDayTicks = ServerTicks(date: date).ticks
                    }
                ),
                displayedComponents: .hourAndMinute
            )
        }
    }
}
