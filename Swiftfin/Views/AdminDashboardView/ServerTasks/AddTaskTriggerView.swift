//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct AddTaskTriggerView: View {

    @ObservedObject
    var observer: ServerTaskObserver

    @Router
    private var router

    @State
    private var taskTriggerInfo: TaskTriggerInfo

    private static let defaultTimeOfDayTicks = 0
    private static let defaultDayOfWeek: DayOfWeek = .sunday
    private static let defaultIntervalTicks = Duration.hours(1).ticks

    private let emptyTaskTriggerInfo: TaskTriggerInfo

    private var hasUnsavedChanges: Bool {
        taskTriggerInfo != emptyTaskTriggerInfo
    }

    private var isDuplicate: Bool {
        observer.task.triggers?.contains(where: { $0 == taskTriggerInfo }) ?? false
    }

    init(observer: ServerTaskObserver) {
        self.observer = observer

        let newTrigger = TaskTriggerInfo(
            dayOfWeek: nil,
            intervalTicks: nil,
            maxRuntimeTicks: nil,
            timeOfDayTicks: nil,
            type: TaskTriggerInfoType.startupTrigger
        )

        _taskTriggerInfo = State(initialValue: newTrigger)
        self.emptyTaskTriggerInfo = newTrigger
    }

    // MARK: - Trigger Type Row

    @ViewBuilder
    private var triggerTypeRow: some View {
        Picker(
            L10n.type,
            selection: $taskTriggerInfo.type
        ) {
            ForEach(TaskTriggerInfoType.allCases, id: \.self) { type in
                Text(type.displayTitle)
                    .tag(type as TaskTriggerInfoType?)
            }
        }
        .onChange(of: taskTriggerInfo.type) { newType in
            resetValuesForNewType(newType: newType)
        }
    }

    private func resetValuesForNewType(newType: TaskTriggerInfoType?) {
        taskTriggerInfo.type = newType
        let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks

        switch newType {
        case .dailyTrigger:
            taskTriggerInfo.timeOfDayTicks = Self.defaultTimeOfDayTicks
            taskTriggerInfo.dayOfWeek = nil
            taskTriggerInfo.intervalTicks = nil
        case .weeklyTrigger:
            taskTriggerInfo.timeOfDayTicks = Self.defaultTimeOfDayTicks
            taskTriggerInfo.dayOfWeek = Self.defaultDayOfWeek
            taskTriggerInfo.intervalTicks = nil
        case .intervalTrigger:
            taskTriggerInfo.intervalTicks = Self.defaultIntervalTicks
            taskTriggerInfo.timeOfDayTicks = nil
            taskTriggerInfo.dayOfWeek = nil
        case .startupTrigger:
            taskTriggerInfo.timeOfDayTicks = nil
            taskTriggerInfo.dayOfWeek = nil
            taskTriggerInfo.intervalTicks = nil
        default:
            taskTriggerInfo.timeOfDayTicks = nil
            taskTriggerInfo.dayOfWeek = nil
            taskTriggerInfo.intervalTicks = nil
        }

        taskTriggerInfo.maxRuntimeTicks = maxRuntimeTicks
    }

    // MARK: - Time Row

    @ViewBuilder
    private var timeRow: some View {
        DatePicker(
            L10n.time,
            selection: Binding<Date>(
                get: {
                    Duration.ticks(
                        taskTriggerInfo.timeOfDayTicks ?? Self.defaultTimeOfDayTicks
                    ).timeOfDayDate
                },
                set: { date in
                    taskTriggerInfo.timeOfDayTicks = Duration.timeOfDay(date).ticks
                }
            ),
            displayedComponents: .hourAndMinute
        )
    }

    // MARK: - Interval Row

    @ViewBuilder
    private var intervalRow: some View {
        StateAdapter(
            initialValue: (
                isPresented: false,
                interval: Duration.ticks(taskTriggerInfo.intervalTicks ?? 0) as Duration?
            )
        ) { alert in
            ChevronButton(
                L10n.every,
                content: Text(Duration.ticks(taskTriggerInfo.intervalTicks ?? 0), format: .hourMinuteAbbreviated)
            ) {
                alert.isPresented.wrappedValue = true
            }
            .alert(L10n.every, isPresented: alert.isPresented) {
                TextField(
                    L10n.minutes,
                    value: alert.interval.map(
                        getter: { $0.map { Int($0.minutes) } },
                        setter: { Duration.minutes($0 ?? 0) }
                    ),
                    format: .number
                )
                .keyboardType(.numberPad)

                Button(L10n.save) {
                    if let interval = alert.interval.wrappedValue, interval != .zero {
                        taskTriggerInfo.intervalTicks = interval.ticks
                    } else {
                        taskTriggerInfo.intervalTicks = nil
                    }
                }

                Button(L10n.cancel, role: .cancel) {
                    if let existingIntervalTicks = taskTriggerInfo.intervalTicks {
                        alert.interval.wrappedValue = Duration.ticks(existingIntervalTicks)
                    } else {
                        alert.interval.wrappedValue = nil
                    }
                }
            } message: {
                Text(L10n.taskTriggerInterval)
            }
        }
    }

    // MARK: - Time Limit Section

    @ViewBuilder
    private var timeLimitSection: some View {
        Section {
            StateAdapter(
                initialValue: (
                    isPresented: false,
                    timeLimit: Int(Duration.ticks(taskTriggerInfo.maxRuntimeTicks ?? 0).hours) as Int?
                )
            ) { alert in
                ChevronButton(
                    L10n.timeLimit.localizedCapitalized,
                    content: timeLimitSubtitle
                ) {
                    alert.isPresented.wrappedValue = true
                }
                .alert(L10n.timeLimit.localizedCapitalized, isPresented: alert.isPresented) {
                    TextField(
                        L10n.hours,
                        value: alert.timeLimit,
                        format: .number
                    )
                    .keyboardType(.numberPad)

                    Button(L10n.save) {
                        let timeLimit = alert.timeLimit.wrappedValue

                        if timeLimit != nil && timeLimit != 0 {
                            taskTriggerInfo.maxRuntimeTicks = Duration.hours(timeLimit ?? 0).ticks
                        } else {
                            taskTriggerInfo.maxRuntimeTicks = nil
                        }
                    }

                    Button(L10n.cancel, role: .cancel) {
                        if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks {
                            alert.timeLimit.wrappedValue = Int(Duration.ticks(maxRuntimeTicks).hours)
                        } else {
                            alert.timeLimit.wrappedValue = nil
                        }
                    }
                } message: {
                    Text(L10n.taskTriggerTimeLimit)
                }
            }
        }
    }

    private var timeLimitSubtitle: String {
        if let maxRuntimeTicks = taskTriggerInfo.maxRuntimeTicks {
            Duration.ticks(maxRuntimeTicks).formatted(.hourMinuteAbbreviated)
        } else {
            L10n.none
        }
    }

    // MARK: - Body

    var body: some View {
        StateAdapter(initialValue: false) { isPresentingNotSaved in
            Form {
                Section {
                    triggerTypeRow

                    if let taskType = taskTriggerInfo.type {
                        if taskType == TaskTriggerInfoType.dailyTrigger {
                            timeRow
                        } else if taskType == TaskTriggerInfoType.weeklyTrigger {
                            Picker(
                                L10n.dayOfWeek,
                                selection: $taskTriggerInfo.dayOfWeek.coalesce(Self.defaultDayOfWeek)
                            ) {
                                ForEach(DayOfWeek.allCases, id: \.self) { day in
                                    Text(day.displayTitle)
                                        .tag(day)
                                }
                            }

                            timeRow
                        } else if taskType == TaskTriggerInfoType.intervalTrigger {
                            intervalRow
                        }
                    }
                } footer: {
                    if isDuplicate {
                        Label(L10n.triggerAlreadyExists, systemImage: "exclamationmark.circle.fill")
                            .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                    }
                }

                timeLimitSection
            }
            .animation(.linear(duration: 0.2), value: isDuplicate)
            .animation(.linear(duration: 0.2), value: taskTriggerInfo.type)
            .interactiveDismissDisabled(true)
            .navigationTitle(L10n.addTrigger.localizedCapitalized)
            .backport
            .toolbarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                if hasUnsavedChanges {
                    isPresentingNotSaved.wrappedValue = true
                } else {
                    router.dismiss()
                }
            }
            .topBarTrailing {
                let saveAction: () -> Void = {
                    UIDevice.impact(.light)

                    observer.addTrigger(taskTriggerInfo)
                    router.dismiss()
                }

                Group {
                    if #available(iOS 26, *) {
                        Button(L10n.save, role: .confirm, action: saveAction)
                    } else {
                        Button(L10n.save, action: saveAction)
                            .backport
                            .buttonStyle(.glassProminent)
                            .controlSize(.small)
                    }
                }
                .disabled(isDuplicate)
            }
            .alert(L10n.unsavedChangesMessage, isPresented: isPresentingNotSaved) {
                Button(L10n.close, role: .destructive) {
                    router.dismiss()
                }
                Button(L10n.cancel, role: .cancel) {
                    isPresentingNotSaved.wrappedValue = false
                }
            }
        }
    }
}
