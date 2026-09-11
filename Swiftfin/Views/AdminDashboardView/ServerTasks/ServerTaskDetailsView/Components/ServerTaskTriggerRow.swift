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

extension ServerTaskDetailsView {

    struct TriggerRow: View {

        @State
        private var isPresentingDeleteConfirmation = false

        let taskTriggerInfo: TaskTriggerInfo
        let onDelete: () -> Void

        // TODO: make FormatStyle
        private var buttonLabel: String {

            guard let triggerType = taskTriggerInfo.type else { return L10n.unknown }

            switch triggerType {
            case .dailyTrigger:
                if let timeOfDayTicks = taskTriggerInfo.timeOfDayTicks {
                    return L10n.itemAtItem(
                        triggerType.displayTitle,
                        Duration.ticks(timeOfDayTicks)
                            .timeOfDayDate
                            .formatted(date: .omitted, time: .shortened)
                    )
                }
            case .weeklyTrigger:
                if let dayOfWeek = taskTriggerInfo.dayOfWeek,
                   let timeOfDayTicks = taskTriggerInfo.timeOfDayTicks
                {
                    return L10n.itemAtItem(
                        dayOfWeek.rawValue.capitalized,
                        Duration.ticks(timeOfDayTicks)
                            .timeOfDayDate
                            .formatted(date: .omitted, time: .shortened)
                    )
                }
            case .intervalTrigger:
                if let intervalTicks = taskTriggerInfo.intervalTicks {
                    return L10n.everyInterval(
                        Duration.ticks(intervalTicks)
                            .formatted(.hourMinuteAbbreviated)
                    )
                }
            case .startupTrigger:
                return triggerType.displayTitle
            }

            return L10n.unknown
        }

        @ViewBuilder
        private var contentView: some View {
            HStack {
                VStack(alignment: .leading) {

                    Text(buttonLabel)
                        .fontWeight(.semibold)

                    Group {
                        if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks {
                            Text(
                                L10n.timeLimitLabelWithValue(
                                    Duration.ticks(maxRuntimeTicks).formatted(.hourMinuteAbbreviated)
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

                Image(systemName: (taskTriggerInfo.type ?? .startupTrigger).systemImage)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
        }

        var body: some View {
            contentView
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(L10n.delete, systemImage: "trash") {
                        isPresentingDeleteConfirmation = true
                    }
                    .tint(.red)
                }
                .confirmationDialog(
                    L10n.delete,
                    isPresented: $isPresentingDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(L10n.cancel, role: .cancel) {}

                    Button(L10n.delete, role: .destructive, action: onDelete)
                } message: {
                    Text(L10n.deleteSelectedConfirmation)
                }
        }
    }
}
