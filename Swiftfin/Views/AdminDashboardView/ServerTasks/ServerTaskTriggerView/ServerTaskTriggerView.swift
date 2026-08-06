//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import JellyfinAPI
import SwiftUI

struct ServerTaskTriggerView: View {

    @ObservedObject
    var viewModel: TaskViewModel

    @Router
    private var router

    @State
    private var taskTriggerInfo = TaskTriggerInfo(type: .startupTrigger)

    private var isDuplicate: Bool {
        viewModel.task.triggers?.contains(where: { $0 == taskTriggerInfo }) == true
    }

    @ViewBuilder
    private var dayPicker: some View {
        Picker(
            L10n.dayOfWeek,
            selection: $taskTriggerInfo.dayOfWeek.coalesce(.sunday)
        )
    }

    @ViewBuilder
    private var timePicker: some View {
        DatePicker(
            L10n.time,
            selection: Binding<Date>(
                get: {
                    Duration.ticks(
                        taskTriggerInfo.timeOfDayTicks ?? 0
                    ).timeOfDayDate
                },
                set: { date in
                    taskTriggerInfo.timeOfDayTicks = Duration.timeOfDay(date).ticks
                }
            ),
            displayedComponents: .hourAndMinute
        )
    }

    @ViewBuilder
    private var intervalPicker: some View {
        HourMinutePicker(
            title: L10n.every,
            interval: $taskTriggerInfo.intervalTicks.map(
                getter: { Duration.ticks($0 ?? 0).seconds },
                setter: { $0 == 0 ? nil : Duration.seconds($0).ticks }
            ),
            maximumHours: 168,
            noneStyle: .dash(1)
        )
    }

    @ViewBuilder
    private var contentView: some View {
        Form {
            Section {

                Picker(
                    L10n.type,
                    selection: $taskTriggerInfo.type.coalesce(.startupTrigger)
                )
                .onChange(of: taskTriggerInfo.type) { _ in
                    taskTriggerInfo.reset()
                }

                switch taskTriggerInfo.type {
                case .dailyTrigger:
                    timePicker
                case .weeklyTrigger:
                    dayPicker
                    timePicker
                case .intervalTrigger:
                    intervalPicker
                default:
                    EmptyView()
                }
            } footer: {
                if isDuplicate {
                    Label(L10n.triggerAlreadyExists, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            Section {
                HourMinutePicker(
                    title: L10n.timeLimit.localizedCapitalized,
                    interval: $taskTriggerInfo.maxRuntimeTicks.map(
                        getter: { Duration.ticks($0 ?? 0).seconds },
                        setter: { $0 == 0 ? nil : Duration.seconds($0).ticks }
                    ),
                    maximumHours: 168,
                    noneStyle: .text
                )
            }
        }
    }

    var body: some View {
        StateAdapter(initialValue: false) { isPresentingNotSaved in
            contentView
                .animation(.linear(duration: 0.2), value: isDuplicate)
                .animation(.linear(duration: 0.2), value: taskTriggerInfo.type)
                .interactiveDismissDisabled(true)
                .navigationTitle(L10n.addTrigger.localizedCapitalized)
                .backport
                .toolbarTitleDisplayMode(.inline)
                .navigationBarCloseButton {
                    if taskTriggerInfo != TaskTriggerInfo(type: .startupTrigger) {
                        isPresentingNotSaved.wrappedValue = true
                    } else {
                        router.dismiss()
                    }
                }
                .topBarTrailing {
                    let saveAction: () -> Void = {
                        UIDevice.impact(.light)
                        viewModel.addTrigger(taskTriggerInfo)
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
