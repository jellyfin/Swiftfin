//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Stinsen
import SwiftUI

extension EditServerTaskView {

    struct TriggerRow: View {

        let taskTriggerInfo: TaskTriggerInfo

        // MARK: - Body

        var body: some View {
            HStack {
                VStack(alignment: .leading) {

                    Text(triggerDisplayText(for: taskTriggerInfo.type))
                        .fontWeight(.semibold)

                    Group {
                        if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks {
                            Text(
                                L10n.timeLimitLabelWithValue(
                                    ServerTicks(maxRuntimeTicks)
                                        .seconds.formatted(.hourMinute)
                                )
                            )
                        } else {
                            Text(L10n.noRuntimeLimit)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: (taskTriggerInfo.type ?? .startup).systemImage)
                    .backport
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
        }

        // MARK: - Trigger Display Text

        private func triggerDisplayText(for triggerType: TaskTriggerType?) -> String {

            guard let triggerType else { return L10n.unknown }

            switch triggerType {
            case .daily:
                if let timeOfDayTicks = taskTriggerInfo.timeOfDayTicks {
                    return L10n.itemAtItem(
                        triggerType.displayTitle,
                        ServerTicks(timeOfDayTicks)
                            .date.formatted(date: .omitted, time: .shortened)
                    )
                }
            case .weekly:
                if let dayOfWeek = taskTriggerInfo.dayOfWeek,
                   let timeOfDayTicks = taskTriggerInfo.timeOfDayTicks
                {
                    return L10n.itemAtItem(
                        dayOfWeek.rawValue.capitalized,
                        ServerTicks(timeOfDayTicks)
                            .date.formatted(date: .omitted, time: .shortened)
                    )
                }
            case .interval:
                if let intervalTicks = taskTriggerInfo.intervalTicks {
                    return L10n.everyInterval(
                        ServerTicks(intervalTicks)
                            .seconds.formatted(.hourMinute)
                    )
                }
            case .startup:
                return triggerType.displayTitle
            }

            return L10n.unknown
        }
    }
}
