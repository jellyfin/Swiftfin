//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: observe running status
//       - stop
//       - run

struct EditScheduledTaskView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @ObservedObject
    var observer: ServerTaskObserver

    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var selectedTrigger: TaskTriggerInfo?

    // MARK: - Task Details Section

    @ViewBuilder
    private var detailsSection: some View {
        Section(L10n.details) {
            if let category = observer.task.category {
                TextPairView(leading: L10n.category, trailing: category)
            }
        }
    }

    // MARK: - Last Run Details Section

    @ViewBuilder
    private func lastRunSection(_ lastExecutionResult: TaskResult) -> some View {
        Section(L10n.lastRun) {
            if let status = lastExecutionResult.status {
                TextPairView(L10n.status, value: Text(status.displayTitle))
            }
            if let endTimeUtc = lastExecutionResult.endTimeUtc {
                TextPairView(L10n.executed, value: Text("\(endTimeUtc, format: .relative(presentation: .numeric, unitsStyle: .narrow))"))
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Last Error Details Section

    @ViewBuilder
    private func lastErrorSection(_ lastExecutionResult: TaskResult) -> some View {
        Section(L10n.errorDetails) {
            if let errorMessage = lastExecutionResult.errorMessage {
                Text(errorMessage)
            }
            if let longErrorMessage = lastExecutionResult.longErrorMessage {
                Text(longErrorMessage)
            }
        }
    }

    // MARK: - Task Current Running Details Section

    @ViewBuilder
    private func currentRunningSection(_ task: TaskInfo) -> some View {
        Section(L10n.progress) {
            if let status = task.state {
                TextPairView(L10n.status, value: Text(status.displayTitle))
            }

            if let currentProgressPercentage = task.currentProgressPercentage {
                TextPairView(
                    L10n.taskCompleted,
                    value: Text("\(currentProgressPercentage / 100, format: .percent.precision(.fractionLength(1)))")
                )
                .monospacedDigit()
            }
        }
    }

    // MARK: - Task Triggers Section

    @ViewBuilder
    private var triggersSection: some View {
        Section(L10n.triggers) {
            if let triggers = observer.task.triggers, !triggers.isEmpty {
                ForEach(triggers, id: \.self) { trigger in
                    TriggerRow(taskTriggerInfo: trigger)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(L10n.delete) {
                                selectedTrigger = trigger
                                isPresentingDeleteConfirmation = true
                            }
                            .tint(.red)
                        }
                }
            } else {
                Button(L10n.addTaskTrigger) {
                    router.route(to: \.addScheduledTaskTrigger, observer)
                }
            }
        }
    }

    // MARK: - Trigger Haptic Feedback

    private func triggerHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIDevice.impact(style)
    }

    // MARK: - Body

    var body: some View {
        List {
            ListTitleSection(
                observer.task.name ?? L10n.unknown,
                description: observer.task.description
            )

            detailsSection

            // Only Create the Last Run Section if there are Last Execution Results Available
            if let lastExecutionResult = observer.task.lastExecutionResult {
                lastRunSection(lastExecutionResult)

                // Only Create the Last Error Section if there are Errors Available
                // Errors can only exist if there is Last Execution Results
                if lastExecutionResult.errorMessage != nil {
                    lastErrorSection(lastExecutionResult)
                }
            }

            // Only Create the Current Running Section if there is an Active Status
            if observer.task.state == .running || observer.task.state == .cancelling {
                currentRunningSection(observer.task)
            }

            triggersSection
        }
        .navigationTitle(L10n.task)
        .topBarTrailing {
            if observer.task.triggers?.isEmpty == false {
                Button(L10n.add) {
                    triggerHapticFeedback()
                    router.route(to: \.addScheduledTaskTrigger, observer)
                }
                .buttonStyle(.toolbarPill)
            }
        }
        .confirmationDialog(
            L10n.deleteTrigger,
            isPresented: $isPresentingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.cancel, role: .cancel) {}

            Button(L10n.delete, role: .destructive) {
                if let selectedTrigger = selectedTrigger {
                    observer.send(.removeTrigger(selectedTrigger))
                }
            }
        } message: {
            Text(L10n.deleteTriggerConfirmationMessage)
        }
    }
}
