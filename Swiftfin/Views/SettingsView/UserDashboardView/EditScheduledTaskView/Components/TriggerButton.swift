//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Stinsen
import SwiftUI

extension EditScheduledTaskView {

    struct TriggerButton: View {

        var taskTriggerInfo: TaskTriggerInfo
        var taskTriggerType: TaskTriggerType
        let onSelect: () -> Void

        @State
        private var isPresentingConfirmation = false

        var body: some View {
            Button(action: {
                isPresentingConfirmation = true
            }) {
                HStack {
                    iconView
                        .padding(.horizontal, 4)
                    labelView
                    Spacer()
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.red)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .confirmationDialog(L10n.deleteTrigger, isPresented: $isPresentingConfirmation, actions: {
                Button(L10n.cancel, role: .cancel) {}
                Button(L10n.delete, role: .destructive) {
                    onSelect()
                }
            }, message: {
                Text(L10n.deleteTriggerConfirmationMessage)
            })
        }

        // MARK: - Label View

        private var labelView: some View {
            VStack(alignment: .leading) {
                switch taskTriggerType {
                case .startup:
                    Text(taskTriggerType.displayTitle)
                        .fontWeight(.semibold)

                case .daily:
                    if let timeOfDayTicks = taskTriggerInfo.timeOfDayTicks {
                        Text(L10n.itemAtItem(taskTriggerType.displayTitle, ticksToSeconds(timeOfDayTicks).formatted(.hourMinute)))
                            .fontWeight(.semibold)
                    }

                case .interval:
                    if let intervalTicks = taskTriggerInfo.intervalTicks {
                        Text(L10n.everyInterval(ticksToSeconds(intervalTicks).formatted(.hourMinute)))
                            .fontWeight(.semibold)
                    }

                case .weekly:
                    if let dayOfWeek = taskTriggerInfo.dayOfWeek, let timeOfDayTicks = taskTriggerInfo.timeOfDayTicks {
                        Text(L10n.itemAtItem(dayOfWeek.rawValue.capitalized, ticksToSeconds(timeOfDayTicks).formatted(.hourMinute)))
                            .fontWeight(.semibold)
                    }

                default:
                    Text(L10n.unknown)
                        .fontWeight(.semibold)
                }

                if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks {
                    Text(L10n.timeLimitLabelWithHours(ticksToSeconds(maxRuntimeTicks).formatted(.hourMinute)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }

        // MARK: - Icon View

        private var iconView: some View {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 40, height: 40)

                Image(systemName: taskTriggerType.systemImage)
                    .resizable()
                    .foregroundStyle(.primary)
                    .frame(width: 25, height: 25)
            }
        }

        private func ticksToSeconds(_ time: Int) -> TimeInterval {
            TimeInterval(time / 10_000_000)
        }
    }
}
