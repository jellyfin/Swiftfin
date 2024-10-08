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

    struct DayOfWeekSection: View {
        @Binding
        var taskTriggerInfo: TaskTriggerInfo

        private let defaultDayOfWeek: DayOfWeek = .sunday

        var body: some View {
            if taskTriggerInfo.type == TaskTriggerType.weekly.rawValue {
                Picker(
                    L10n.dayOfWeek,
                    selection: Binding(
                        get: { taskTriggerInfo.dayOfWeek ?? defaultDayOfWeek },
                        set: { taskTriggerInfo.dayOfWeek = $0 }
                    )
                ) {
                    ForEach(DayOfWeek.allCases, id: \.self) { day in
                        Text(day.rawValue.capitalized).tag(day)
                    }
                }
                .pickerStyle(.menu)
                .foregroundStyle(.primary)
            }
        }
    }
}
