//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct EditServerTaskView: View {

    // MARK: - Observed & Environment Objects

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @ObservedObject
    var observer: ServerTaskObserver

    // MARK: - Trigger Variables

    @State
    private var selectedTrigger: TaskTriggerInfo?

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Body

    var body: some View {
        List {
            ListTitleSection(
                observer.task.name ?? L10n.unknown,
                description: observer.task.description
            )

            ProgressSection(observer: observer)

            if let category = observer.task.category {
                DetailsSection(category: category)
            }

            if let lastExecutionResult = observer.task.lastExecutionResult {
                if let status = lastExecutionResult.status, let endTime = lastExecutionResult.endTimeUtc {
                    LastRunSection(status: status, endTime: endTime)
                }

                if let errorMessage = lastExecutionResult.errorMessage {
                    LastErrorSection(message: errorMessage)
                }
            }

            TriggersSection(observer: observer)
        }
        .animation(.linear(duration: 0.2), value: observer.state)
        .animation(.linear(duration: 0.1), value: observer.task.state)
        .animation(.linear(duration: 0.1), value: observer.task.triggers)
        .navigationTitle(L10n.task)
        .topBarTrailing {

            if observer.backgroundStates.contains(.updatingTriggers) {
                ProgressView()
            }

            if let triggers = observer.task.triggers, triggers.isNotEmpty {
                Button(L10n.add) {
                    UIDevice.impact(.light)
                    router.route(to: \.addServerTaskTrigger, observer)
                }
                .buttonStyle(.toolbarPill)
            }
        }
        .onReceive(observer.events) { event in
            switch event {
            case let .error(eventError):
                error = eventError
            }
        }
        .errorMessage($error)
    }
}
