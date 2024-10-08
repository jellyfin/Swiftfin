//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: last run details
//       - result, show error if available
// TODO: observe running status
//       - stop
//       - run
//       - progress

struct EditScheduledTaskView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @ObservedObject
    var observer: ServerTaskObserver

    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var selectedTrigger: TaskTriggerInfo?

    private var detailsSection: some View {
        Section(L10n.details) {
            if let category = observer.task.category {
                TextPairView(leading: L10n.category, trailing: category)
            }

            if let lastEndTime = observer.task.lastExecutionResult?.endTimeUtc {
                TextPairView(L10n.lastRun, value: Text("\(lastEndTime, format: .relative(presentation: .numeric, unitsStyle: .narrow))"))
                    .monospacedDigit()
            }
        }
    }

    @ViewBuilder
    private var triggersSection: some View {
        Section(L10n.triggers) {
            if let triggers = observer.task.triggers,
               triggers.isNotEmpty
            {
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

    var body: some View {
        List {
            ListTitleSection(
                observer.task.name ?? L10n.unknown,
                description: observer.task.description
            )

            detailsSection

            triggersSection
        }
        .navigationTitle(L10n.task)
        .topBarTrailing {
            if let triggers = observer.task.triggers,
               triggers.isNotEmpty
            {
                Button(L10n.add) {
                    UIDevice.impact(.light)
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
                // TODO: delete selected trigger
            }
        } message: {
            Text(L10n.deleteTriggerConfirmationMessage)
        }
    }
}
