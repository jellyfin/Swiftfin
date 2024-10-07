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

    private let createTrigger: Bool
    private let source: Binding<TaskTriggerInfo>?

    @State
    private var isPresentingNotSaved = false
    @State
    private var isPresentingTimeLimit = false

    @Environment(\.dismiss)
    private var dismiss

    private let allowedTriggerTypes: [TaskTriggerType] = [
        .daily,
        .interval,
        .weekly,
        .startup,
    ]

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

    init(trigger: Binding<TaskTriggerInfo>? = nil, observer: ServerTaskObserver) {
        self.observer = observer
        self.createTrigger = trigger == nil

        if let trigger = trigger {
            let triggerValue = trigger.wrappedValue
            _taskTriggerInfo = State(initialValue: triggerValue)
            self.emptyTaskTriggerInfo = triggerValue
            self.source = trigger
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
            self.source = nil
        }
    }

    @ViewBuilder
    private var triggerTypePicker: some View {
        Picker(
            L10n.triggerType,
            selection: Binding<String?>(
                get: { taskTriggerInfo.type },
                set: { newValue in
                    taskTriggerInfo.type = newValue
                    taskTriggerInfo.intervalTicks = nil
                    taskTriggerInfo.timeOfDayTicks = nil
                    taskTriggerInfo.dayOfWeek = nil
                    guard newValue != nil else { return }
                }
            )
        ) {
            ForEach(allowedTriggerTypes, id: \.rawValue) { type in
                Text(type.displayTitle).tag(type.rawValue as String?)
            }
        }
        .pickerStyle(.menu)
        .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var dayOfWeekPicker: some View {
        if taskTriggerInfo.type == TaskTriggerType.weekly.rawValue {
            Picker(
                L10n.dayOfWeek,
                selection: Binding<DayOfWeek?>(
                    get: { taskTriggerInfo.dayOfWeek },
                    set: { taskTriggerInfo.dayOfWeek = $0 }
                )
            ) {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    Text(day.rawValue).tag(day as DayOfWeek?)
                }
            }
            .pickerStyle(.menu)
            .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private var timePicker: some View {
        if let type = taskTriggerInfo.type,
           type == TaskTriggerType.daily.rawValue || type == TaskTriggerType.weekly.rawValue
        {
            DatePicker(
                L10n.time,
                selection: Binding<Date>(
                    get: {
                        if let ticks = taskTriggerInfo.timeOfDayTicks {
                            let timeInterval = TimeInterval(ticks) / 10_000_000
                            return Date(timeIntervalSince1970: timeInterval)
                        } else {
                            return Date()
                        }
                    },
                    set: { date in
                        let timeInterval = date.timeIntervalSince1970
                        taskTriggerInfo.timeOfDayTicks = Int(timeInterval * 10_000_000)
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .onAppear {
                if taskTriggerInfo.timeOfDayTicks == nil {
                    let defaultTime = Date()
                    taskTriggerInfo.timeOfDayTicks = Int(defaultTime.timeIntervalSince1970 * 10_000_000)
                }
            }
        }
    }

    @ViewBuilder
    private var intervalPicker: some View {
        if taskTriggerInfo.type == TaskTriggerType.interval.rawValue {
            Picker(
                L10n.every,
                selection: Binding<Int?>(
                    get: { taskTriggerInfo.intervalTicks },
                    set: { newValue in
                        taskTriggerInfo.intervalTicks = newValue
                    }
                )
            ) {
                ForEach(TaskTriggerInterval.allCases) { interval in
                    Text(interval.displayTitle).tag(Int(interval.rawValue))
                }
            }
            .pickerStyle(.menu)
            .foregroundStyle(.primary)
        }
    }

    private var timeLimitField: some View {
        Section {
            ChevronButton(
                L10n.timeLimit,
                subtitle: {
                    if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks, maxRuntimeTicks > 0 {
                        let timeInterval = TimeInterval(maxRuntimeTicks) / 10_000_000
                        return Text(timeInterval, format: .hourMinute)
                    } else {
                        return Text(L10n.disabled)
                    }
                }()
            )
            .onSelect {
                isPresentingTimeLimit = true
            }
            .alert(L10n.timeLimit, isPresented: $isPresentingTimeLimit) {
                TextField(
                    L10n.timeLimit,
                    value: Binding(
                        get: {
                            taskTriggerInfo.maxRuntimeTicks.map { Int($0 / (10_000_000 * 3600)) } ?? 0
                        },
                        set: { newValue in
                            taskTriggerInfo.maxRuntimeTicks = Int(TimeInterval(newValue) * 10_000_000 * 3600)
                        }
                    ),
                    format: .number // Use a number format for hours
                )
                .keyboardType(.numberPad)

            } message: {
                Text("Description")
            }
        }
    }

    var body: some View {
        Form {
            triggerTypePicker
            if taskTriggerInfo.type != nil {
                dayOfWeekPicker
                timePicker
                intervalPicker
                timeLimitField
            }
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
        .navigationTitle(createTrigger ? L10n.addTaskTrigger : L10n.editTaskTrigger)
        .topBarTrailing {
            Button(L10n.save) {
                UIDevice.impact(.light)
                observer.send(.addTrigger(taskTriggerInfo))
                dismiss()
            }
            .buttonStyle(.toolbarPill)
            .disabled(!isValid)
        }
        .alert(L10n.changesNotSaved, isPresented: $isPresentingNotSaved) {
            Button(L10n.discardChanges, role: .destructive) {
                dismiss()
            }
            Button(L10n.cancel, role: .cancel) {
                isPresentingNotSaved = false
            }
        } message: {
            Text(L10n.unsavedChangesMessage)
        }
    }
}
