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

    @Router
    private var router

    @CurrentDate
    private var currentDate: Date

    @ObservedObject
    var observer: ServerTaskObserver

    @State
    private var selectedTrigger: TaskTriggerInfo?

    var body: some View {
        List {
            ListTitleSection(
                observer.task.name ?? L10n.unknown,
                description: observer.task.description
            )

            ProgressSection(observer: observer)

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

            TriggersSection(observer: observer)
        }
        .animation(.linear(duration: 0.2), value: observer.state)
        .animation(.linear(duration: 0.1), value: observer.task.state)
        .animation(.linear(duration: 0.1), value: observer.task.triggers)
        .navigationTitle(L10n.task)
        .topBarTrailing {

            if observer.background.states.contains(.observing) || observer.background.states.contains(.updating) {
                ProgressView()
            }

            if let triggers = observer.task.triggers, triggers.isNotEmpty {
                Button(L10n.add) {
                    UIDevice.impact(.light)
                    router.route(to: .addServerTaskTrigger(observer: observer))
                }
                .buttonStyle(.toolbarPill)
            }
        }
        .errorMessage($observer.error)
    }
}
