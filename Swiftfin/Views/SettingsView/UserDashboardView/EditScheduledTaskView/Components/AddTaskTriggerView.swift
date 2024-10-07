//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct AddTaskTriggerView: View {

    @ObservedObject
    var observer: ServerTaskObserver

    @State
    private var taskTriggerInfo: TaskTriggerInfo
    private let emptyTaskTriggerInfo: TaskTriggerInfo

    @State
    private var createTrigger: Bool
    private let allowedTriggerTypes: [TaskTriggerType] = [
        .daily,
        .interval,
        .weekly,
        .startup,
    ]

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var isPresentingNotSaved = false

    private var hasUnsavedChanges: Bool {
        taskTriggerInfo != emptyTaskTriggerInfo
    }

    private var isValid: Bool {
        guard let type = taskTriggerInfo.type else {
            return false
        }
        switch type {
        case TaskTriggerType.daily.rawValue:
            return taskTriggerInfo.timeOfDayTicks != nil
        case TaskTriggerType.weekly.rawValue:
            return taskTriggerInfo.timeOfDayTicks != nil && taskTriggerInfo.dayOfWeek != nil
        case TaskTriggerType.interval.rawValue:
            return taskTriggerInfo.intervalTicks != nil
        case TaskTriggerType.startup.rawValue:
            return true
        default:
            return false
        }
    }

    init(observer: ServerTaskObserver, createTrigger: Bool = true, taskTriggerInfo: TaskTriggerInfo? = nil) {
        self.observer = observer

        if let taskTriggerInfo = taskTriggerInfo {
            _taskTriggerInfo = State(initialValue: taskTriggerInfo)
            self.emptyTaskTriggerInfo = taskTriggerInfo
            self.createTrigger = false
        } else {
            let newTrigger = TaskTriggerInfo(
                dayOfWeek: nil,
                intervalTicks: nil,
                maxRuntimeTicks: nil,
                timeOfDayTicks: nil,
                type: TaskTriggerType.startup.rawValue
            )
            _taskTriggerInfo = State(initialValue: newTrigger)
            self.emptyTaskTriggerInfo = newTrigger
            self.createTrigger = createTrigger
        }
    }

    var body: some View {
        Form {
            TriggerTypeSection(taskTriggerInfo: $taskTriggerInfo, allowedTriggerTypes: allowedTriggerTypes)
            DayOfWeekSection(taskTriggerInfo: $taskTriggerInfo)
            TimeSection(taskTriggerInfo: $taskTriggerInfo)
            IntervalSection(taskTriggerInfo: $taskTriggerInfo)
            TimeLimitSection(taskTriggerInfo: $taskTriggerInfo)
        }
        .interactiveDismissDisabled(hasUnsavedChanges)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarCloseButton {
            if hasUnsavedChanges {
                isPresentingNotSaved = true
            } else {
                dismiss()
            }
        }
        .navigationTitle(L10n.customProfile)
        .topBarTrailing {
            Button(L10n.save) {
                if createTrigger {
                    observer.send(.addTrigger(taskTriggerInfo))
                }
                UIDevice.impact(.light)
                dismiss()
            }
            .buttonStyle(.toolbarPill)
            .disabled(!isValid)
        }
        .alert(L10n.unsavedChangesMessage, isPresented: $isPresentingNotSaved) {
            Button(L10n.close, role: .destructive) {
                dismiss()
            }
            Button(L10n.cancel, role: .cancel) {
                isPresentingNotSaved = false
            }
        }
    }
}
