//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct EditScheduledTaskView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @ObservedObject
    var observer: ServerTaskObserver

    // MARK: - State Variables

    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var showEventAlert = false
    @State
    private var eventSuccess = false
    @State
    private var eventMessage: String = ""
    @State
    private var selectedTrigger: TaskTriggerInfo?

    // MARK: - Cancellables for Combine Subscriptions

    @State
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Body

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

            ManualRunSection(observer: observer)

            if observer.task.state == .running || observer.task.state == .cancelling {
                CurrentRunningSection(task: observer.task)
            }

            TriggersSection(
                triggers: observer.task.triggers,
                isPresentingDeleteConfirmation: $isPresentingDeleteConfirmation,
                selectedTrigger: $selectedTrigger,
                deleteAction: {
                    trigger in observer.send(.removeTrigger(trigger))
                },
                addAction: {
                    router.route(to: \.addScheduledTaskTrigger, observer)
                }
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
        .onAppear {
            handleEvents()
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
        .alert(eventSuccess ? L10n.success : L10n.error, isPresented: $showEventAlert) {} message: {
            Text(eventMessage)
        }
    }

    // MARK: - Handle Events

    private func handleEvents() {
        observer.events
            .sink { event in
                switch event {
                case .created:
                    eventSuccess = true
                    eventMessage = L10n.serverTriggerCreated(observer.task.name ?? L10n.unknown)
                    showEventAlert = true
                case .deleted:
                    eventSuccess = true
                    eventMessage = L10n.serverTriggerDeleted(observer.task.name ?? L10n.unknown)
                    showEventAlert = true
                case let .error(jellyfinError):
                    eventSuccess = false
                    eventMessage = jellyfinError.localizedDescription
                    showEventAlert = true
                }
            }
            .store(in: &cancellables)
    }
}
