//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension EditScheduledTaskView {

    struct TriggersSection: View {

        var triggers: [TaskTriggerInfo]?
        @Binding
        var isPresentingDeleteConfirmation: Bool
        @Binding
        var selectedTrigger: TaskTriggerInfo?
        var deleteAction: (TaskTriggerInfo) -> Void
        var addAction: () -> Void

        var body: some View {
            Section(L10n.triggers) {
                if let triggers = triggers, !triggers.isEmpty {
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
                        addAction()
                    }
                }
            }
        }
    }
}
