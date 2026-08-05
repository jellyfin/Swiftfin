//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EditServerTaskView: View {

    @CurrentDate
    private var currentDate: Date

    @Router
    private var router

    @ObservedObject
    var observer: ServerTaskObserver

    @ViewBuilder
    private var progressSection: some View {
        if observer.task.state == .running || observer.task.state == .cancelling {
            Section(L10n.progress) {
                if let status = observer.task.state {
                    LabeledContent(
                        L10n.status,
                        value: status.displayTitle
                    )
                }

                if let currentProgressPercentage = observer.task.currentProgressPercentage {
                    LabeledContent(
                        L10n.progress,
                        value: currentProgressPercentage / 100,
                        format: .percent.precision(
                            .fractionLength(1)
                        )
                    )
                    .monospacedDigit()
                }

                Button {
                    observer.stop()
                } label: {
                    HStack {
                        Text(L10n.stop)

                        Spacer()

                        Image(systemName: "stop.fill")
                    }
                }
                .foregroundStyle(.red)
            }
        } else {
            Button(L10n.run) {
                observer.start()
            }
        }
    }

    @ViewBuilder
    private var triggersSection: some View {
        StateAdapter(initialValue: (isPresented: false, trigger: nil as TaskTriggerInfo?)) { confirmation in
            Section(L10n.triggers) {
                ForEach(observer.task.triggers ?? [], id: \.self) { trigger in
                    triggerRow(for: trigger)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                confirmation.wrappedValue = (isPresented: true, trigger: trigger)
                            } label: {
                                Label(L10n.delete, systemImage: "trash")
                            }
                            .tint(.red)
                        }
                }

                Button(L10n.add) {
                    UIDevice.impact(.light)
                    router.route(to: .addServerTaskTrigger(observer: observer))
                }
            }
            .confirmationDialog(
                L10n.delete,
                isPresented: confirmation.isPresented,
                titleVisibility: .visible
            ) {
                Button(L10n.cancel, role: .cancel) {}

                Button(L10n.delete, role: .destructive) {
                    if let trigger = confirmation.trigger.wrappedValue {
                        observer.removeTrigger(trigger)
                    }
                }
            } message: {
                Text(L10n.deleteSelectedConfirmation)
            }
        }
    }

    @ViewBuilder
    private func triggerRow(for taskTriggerInfo: TaskTriggerInfo) -> some View {
        HStack {
            VStack(alignment: .leading) {

                Text(triggerDisplayText(for: taskTriggerInfo))
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

    private func triggerDisplayText(for taskTriggerInfo: TaskTriggerInfo) -> String {

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

    // MARK: - Body

    var body: some View {
        List {
            ListTitleSection(
                observer.task.name ?? L10n.unknown,
                description: observer.task.description
            )

            progressSection

            if let category = observer.task.category {
                Section(L10n.details) {
                    LabeledContent(L10n.category, value: category)
                }
            }

            if let lastExecutionResult = observer.task.lastExecutionResult {
                if let status = lastExecutionResult.status, let endTime = lastExecutionResult.endTimeUtc {
                    Section(L10n.lastRun) {

                        LabeledContent(
                            L10n.status,
                            value: status.displayTitle
                        )

                        LabeledContent(L10n.executed, value: endTime, format: .lastSeen)
                            .id(currentDate)
                            .monospacedDigit()
                    }
                }

                if let errorMessage = lastExecutionResult.errorMessage {
                    Section(L10n.errorDetails) {
                        Text(errorMessage)
                    }
                }
            }

            triggersSection
        }
        .animation(.linear(duration: 0.1), value: observer.task.state)
        .animation(.linear(duration: 0.1), value: observer.task.triggers)
        .navigationTitle(L10n.task)
        .topBarTrailing {
            if observer.background.states.contains(.updating) {
                ProgressView()
            }
        }
        .errorMessage($observer.error)
    }
}
