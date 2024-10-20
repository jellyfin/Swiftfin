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

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var isPresentingNotSaved = false

    // MARK: - Default Trigger Values

    static let defaultTimeOfDayTicks = 0
    static let defaultDayOfWeek: DayOfWeek = .sunday
    static let defaultIntervalTicks = 36_000_000_000

    // MARK: - Unsaved Changes Validation

    private var hasUnsavedChanges: Bool {
        taskTriggerInfo != emptyTaskTriggerInfo
    }

    // MARK: - Init

    init(observer: ServerTaskObserver) {
        self.observer = observer

        let newTrigger = TaskTriggerInfo(
            dayOfWeek: nil,
            intervalTicks: nil,
            maxRuntimeTicks: nil,
            timeOfDayTicks: nil,
            type: TaskTriggerType.startup.rawValue
        )

        _taskTriggerInfo = State(initialValue: newTrigger)
        self.emptyTaskTriggerInfo = newTrigger
    }

    // MARK: - View for TaskTriggerType.daily

    @ViewBuilder
    private var dailyView: some View {
        TimeSection(taskTriggerInfo: $taskTriggerInfo)
    }

    // MARK: - View for TaskTriggerType.weekly

    @ViewBuilder
    private var weeklyView: some View {
        DayOfWeekSection(taskTriggerInfo: $taskTriggerInfo)
        TimeSection(taskTriggerInfo: $taskTriggerInfo)
    }

    // MARK: - View for TaskTriggerType.interval

    @ViewBuilder
    private var intervalView: some View {
        IntervalSection(taskTriggerInfo: $taskTriggerInfo)
    }

    // MARK: - Body

    var body: some View {
        Form {
            TriggerTypeSection(taskTriggerInfo: $taskTriggerInfo)

            if let taskType = taskTriggerInfo.type {
                if taskType == TaskTriggerType.daily.rawValue {
                    TimeSection(taskTriggerInfo: $taskTriggerInfo)

                } else if taskType == TaskTriggerType.weekly.rawValue {
                    DayOfWeekSection(taskTriggerInfo: $taskTriggerInfo)
                    TimeSection(taskTriggerInfo: $taskTriggerInfo)

                } else if taskType == TaskTriggerType.interval.rawValue {
                    IntervalSection(taskTriggerInfo: $taskTriggerInfo)
                }
            }

            TimeLimitSection(taskTriggerInfo: $taskTriggerInfo)
        }
        .interactiveDismissDisabled(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            if hasUnsavedChanges {
                isPresentingNotSaved = true
            } else {
                dismiss()
            }
        }
        .navigationTitle(L10n.addTaskTrigger)
        .topBarTrailing {
            Button(L10n.save) {

                UIDevice.impact(.light)

                observer.send(.addTrigger(taskTriggerInfo))
                dismiss()
            }
            .buttonStyle(.toolbarPill)
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
