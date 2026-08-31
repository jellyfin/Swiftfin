//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ServerTaskDetailsView: View {

    @CurrentDate
    private var currentDate: Date

    @ObservedObject
    var viewModel: ServerTaskViewModel

    @Router
    private var router

    private var isRunning: Bool {
        viewModel.task.state == .running || viewModel.task.state == .cancelling
    }

    @ViewBuilder
    private var contentView: some View {
        List {
            ListTitleSection(
                viewModel.task.name ?? L10n.unknown,
                description: viewModel.task.description
            )

            if let category = viewModel.task.category {
                Section(L10n.details) {
                    LabeledContent(L10n.category, value: category)
                }
            }

            if isRunning {
                Section(L10n.progress) {
                    if let status = viewModel.task.state {
                        LabeledContent(
                            L10n.status,
                            value: status.displayTitle
                        )
                    }

                    if let currentProgressPercentage = viewModel.task.currentProgressPercentage {
                        LabeledContent(
                            L10n.progress,
                            value: currentProgressPercentage / 100,
                            format: .percent.precision(
                                .fractionLength(1)
                            )
                        )
                        .monospacedDigit()
                    }
                }
            }

            if let lastExecutionResult = viewModel.task.lastExecutionResult {
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

            Section(L10n.triggers) {
                if let triggers = viewModel.task.triggers {
                    ForEach(triggers, id: \.self) { trigger in
                        TriggerRow(taskTriggerInfo: trigger) {
                            viewModel.removeTrigger(trigger)
                        }
                    }
                }

                Button(L10n.add) {
                    UIDevice.impact(.light)
                    router.route(to: .taskTrigger(viewModel: viewModel))
                }
            }
        }
    }

    var body: some View {
        contentView
            .animation(.linear(duration: 0.1), value: viewModel.task.state)
            .animation(.linear(duration: 0.1), value: viewModel.task.triggers)
            .navigationTitle(L10n.task)
            .topBarTrailing {
                if viewModel.background.states.contains(.updating) {
                    ProgressView()
                }

                if isRunning {
                    if #available(iOS 26, *) {
                        Button(L10n.cancel, role: .cancel, action: viewModel.stop)
                    } else {
                        Button(L10n.cancel, role: .cancel, action: viewModel.stop)
                            .backport
                            .buttonStyle(.glassProminent)
                            .controlSize(.small)
                    }
                } else {
                    if #available(iOS 26, *) {
                        Button(L10n.start, role: .confirm, action: viewModel.start)
                    } else {
                        Button(L10n.start, action: viewModel.start)
                            .backport
                            .buttonStyle(.glassProminent)
                            .controlSize(.small)
                    }
                }
            }
            .errorMessage($viewModel.error)
    }
}
