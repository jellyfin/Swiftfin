//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension EditServerTaskView {

    struct TriggersSection: View {

        @EnvironmentObject
        private var router: AdminDashboardCoordinator.Router

        @ObservedObject
        var observer: ServerTaskObserver

        @State
        private var isPresentingDeleteConfirmation: Bool = false
        @State
        private var selectedTrigger: TaskTriggerInfo?

        var body: some View {
            Section(L10n.triggers) {
                if let triggers = observer.task.triggers, triggers.isNotEmpty {
                    ForEach(triggers, id: \.self) { trigger in
                        TriggerRow(taskTriggerInfo: trigger)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    selectedTrigger = trigger
                                    isPresentingDeleteConfirmation = true
                                } label: {
                                    Label(L10n.delete, systemImage: "trash")
                                }
                                .tint(.red)
                            }
                    }
                } else {
                    Button(L10n.addTrigger) {
                        router.route(to: \.addServerTaskTrigger, observer)
                    }
                }
            }
            .confirmationDialog(
                L10n.deleteTrigger,
                isPresented: $isPresentingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.cancel, role: .cancel) {}

                Button(L10n.delete, role: .destructive) {
                    if let selectedTrigger {
                        observer.send(.removeTrigger(selectedTrigger))
                    }
                }
            } message: {
                Text(L10n.deleteTriggerConfirmationMessage)
            }
        }
    }
}
