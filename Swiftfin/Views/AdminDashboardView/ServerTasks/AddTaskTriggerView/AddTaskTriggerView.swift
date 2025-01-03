//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct AddTaskTriggerView: View {

    @Environment(\.dismiss)
    private var dismiss

    @ObservedObject
    var observer: ServerTaskObserver

    @State
    private var isPresentingNotSaved = false
    @State
    private var taskTriggerInfo: TaskTriggerInfo

    static let defaultTimeOfDayTicks = 0
    static let defaultDayOfWeek: DayOfWeek = .sunday
    static let defaultIntervalTicks = 36_000_000_000
    private let emptyTaskTriggerInfo: TaskTriggerInfo

    private var hasUnsavedChanges: Bool {
        taskTriggerInfo != emptyTaskTriggerInfo
    }

    private var isDuplicate: Bool {
        observer.task.triggers?.contains(where: { $0 == taskTriggerInfo }) ?? false
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
        TimeRow(taskTriggerInfo: $taskTriggerInfo)
    }

    // MARK: - View for TaskTriggerType.weekly

    @ViewBuilder
    private var weeklyView: some View {
        DayOfWeekRow(taskTriggerInfo: $taskTriggerInfo)
        TimeRow(taskTriggerInfo: $taskTriggerInfo)
    }

    // MARK: - View for TaskTriggerType.interval

    @ViewBuilder
    private var intervalView: some View {
        IntervalRow(taskTriggerInfo: $taskTriggerInfo)
    }

    // MARK: - Body

    var body: some View {
        Form {
            Section {
                TriggerTypeRow(taskTriggerInfo: $taskTriggerInfo)

                if let taskType = taskTriggerInfo.type {
                    if taskType == TaskTriggerType.daily.rawValue {
                        dailyView
                    } else if taskType == TaskTriggerType.weekly.rawValue {
                        weeklyView
                    } else if taskType == TaskTriggerType.interval.rawValue {
                        intervalView
                    }
                }
            } footer: {
                if isDuplicate {
                    Label(L10n.triggerAlreadyExists, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            TimeLimitSection(taskTriggerInfo: $taskTriggerInfo)
        }
        .animation(.linear(duration: 0.2), value: isDuplicate)
        .animation(.linear(duration: 0.2), value: taskTriggerInfo.type)
        .interactiveDismissDisabled(true)
        .navigationTitle(L10n.addTrigger)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            if hasUnsavedChanges {
                isPresentingNotSaved = true
            } else {
                dismiss()
            }
        }
        .topBarTrailing {
            Button(L10n.save) {

                UIDevice.impact(.light)

                observer.send(.addTrigger(taskTriggerInfo))
                dismiss()
            }
            .buttonStyle(.toolbarPill)
            .disabled(isDuplicate)
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
