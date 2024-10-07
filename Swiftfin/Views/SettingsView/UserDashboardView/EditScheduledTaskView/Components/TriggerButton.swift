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

        // MARK: - Body

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
                        Text(L10n.itemAtItem(
                            taskTriggerType.displayTitle,
                            timeFromTicks(timeOfDayTicks).formatted(date: .omitted, time: .shortened)
                        ))
                        .fontWeight(.semibold)
                    }

                case .interval:
                    if let intervalTicks = taskTriggerInfo.intervalTicks {
                        Text(L10n.everyInterval(
                            timeIntervalFromTicks(intervalTicks).formatted(.hourMinute)
                        ))
                        .fontWeight(.semibold)
                    }

                case .weekly:
                    if let dayOfWeek = taskTriggerInfo.dayOfWeek,
                       let timeOfDayTicks = taskTriggerInfo.timeOfDayTicks
                    {
                        Text(L10n.itemAtItem(
                            dayOfWeek.rawValue.capitalized,
                            timeFromTicks(timeOfDayTicks).formatted(date: .omitted, time: .shortened)
                        ))
                        .fontWeight(.semibold)
                    }

                default:
                    Text(L10n.unknown)
                        .fontWeight(.semibold)
                }

                if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks {
                    Text(
                        L10n.timeLimitLabelWithHours(
                            timeIntervalFromTicks(maxRuntimeTicks).formatted(.hourMinute)
                        )
                    )
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

        // MARK: - Convert Ticks to TimeInterval and Time from Ticks

        private func timeIntervalFromTicks(_ ticks: Int) -> TimeInterval {
            TimeInterval(ticks) / 10_000_000
        }

        private func timeFromTicks(_ ticks: Int) -> Date {
            let totalSeconds = timeIntervalFromTicks(ticks)
            let hours = Int(totalSeconds) / 3600
            let minutes = (Int(totalSeconds) % 3600) / 60
            var components = DateComponents()
            components.hour = hours
            components.minute = minutes
            return Calendar.current.date(from: components) ?? Date()
        }
    }
}
