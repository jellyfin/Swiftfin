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
    private var router: AdminDashboardCoordinator.Router

    @ObservedObject
    var observer: ServerTaskObserver

    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var selectedTrigger: TaskTriggerInfo?

    var body: some View {
        List {
            ListTitleSection(
                observer.task.name ?? L10n.unknown,
                description: observer.task.description
            )

            DetailsSection(category: observer.task.category)

            if let lastExecutionResult = observer.task.lastExecutionResult {
                LastRunSection(lastExecutionResult: lastExecutionResult)

                if lastExecutionResult.errorMessage != nil {
                    LastErrorSection(lastExecutionResult: lastExecutionResult)
                }
            }

            if observer.task.state == .running || observer.task.state == .cancelling {
                CurrentRunningSection(task: observer.task)
            }

            TriggersSection(
                triggers: observer.task.triggers,
                isPresentingDeleteConfirmation: $isPresentingDeleteConfirmation,
                selectedTrigger: $selectedTrigger,
                deleteAction: { trigger in observer.send(.removeTrigger(trigger)) },
                addAction: { router.route(to: \.addScheduledTaskTrigger, observer) }
            )
        }
        .navigationTitle(L10n.task)
        .topBarTrailing {
            if observer.task.triggers?.isEmpty == false {
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
                if let selectedTrigger = selectedTrigger {
                    observer.send(.removeTrigger(selectedTrigger))
                }
            }
        } message: {
            Text(L10n.deleteTriggerConfirmationMessage)
        }
    }
}
