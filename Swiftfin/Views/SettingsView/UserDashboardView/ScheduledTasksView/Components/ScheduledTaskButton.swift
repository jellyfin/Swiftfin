//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ScheduledTasksView {

    struct ScheduledTaskButton: View {

        // MARK: - Tracked States

        @State
        private var isCancelling = false
        @State
        private var isStarting = false
        @State
        private var isPresentingConfirmation = false

        var task: TaskInfo
        var onSelect: () -> Void
        var onCancel: () -> Void

        // MARK: - Body

        @ViewBuilder
        var body: some View {
            Button {
                isCancelling = false
                isPresentingConfirmation = true
            } label: {
                HStack {
                    taskView

                    Spacer()

                    statusView
                }
            }
            .foregroundStyle(.primary, .secondary)
            .confirmationDialog(
                confirmationDialogText,
                isPresented: $isPresentingConfirmation,
                titleVisibility: .visible
            ) {
                Button(task.lastExecutionResult?.status == .completed ? "Run" : "Rerun") {
                    onSelect()
                    isStarting = true
                }
            }
            .onChange(of: task.lastExecutionResult?.startTimeUtc) { _ in
                isStarting = false
            }
        }

        // MARK: - Task Details Section

        @ViewBuilder
        private var taskView: some View {
            VStack(alignment: .leading, spacing: 4) {

                Text(task.name?.localizedCapitalized ?? L10n.unknown)
                    .fontWeight(.semibold)

                Group {
                    if !isActive {
                        if let taskEndTime = task.lastExecutionResult?.endTimeUtc {
                            Text("Last ran \(taskEndTime, format: .relative(presentation: .numeric, unitsStyle: .narrow))")
                        }

                        taskResultView
                    } else {
                        Text("Running...")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }

        // MARK: - Task Status Section

        @ViewBuilder
        private var statusView: some View {
            if isActive {
                if isCancelling {
                    Text(L10n.canceled)
                        .foregroundStyle(.red)
                } else {

                    ProgressView(value: task.currentProgressPercentage)
                        .progressViewStyle(.gauge)

                    Image(systemName: "stop.fill")
                        .foregroundStyle(.red)
                }
            } else {
                Image(systemName: "play.fill")
                    .foregroundStyle(.secondary)
            }
        }

        // MARK: - Task Status View

        @ViewBuilder
        private var taskResultView: some View {
            if let taskStatus = task.lastExecutionResult?.status, taskStatus != .completed {
                Label(
                    taskStatus.rawValue,
                    systemImage: "exclamationmark.circle.fill"
                )
                .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                .foregroundStyle(.orange)
            }
        }

        // MARK: - Task is Active

        private var isActive: Bool {
            task.currentProgressPercentage != nil || isStarting
        }

        // MARK: - Task Confirmation

        private var confirmationDialogText: String {
            """
            \(task.name?.localizedCapitalized ?? L10n.unknown)
            \(task.lastExecutionResult?.longErrorMessage ?? "")
            """
        }

        // MARK: - Cancel Button

        @ViewBuilder
        private var cancelButton: some View {
//            Image(systemName: "xmark.circle.fill")
//                .backport
//                .fontWeight(.bold)
//                .symbolRenderingMode(.palette)
//                .foregroundStyle(.black, .pink)

            Image(systemName: "stop.fill")
                .backport
                .fontWeight(.bold)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.red)
                .frame(width: 20)

//                .foregroundStyle(.red)
//                .onTapGesture {
//                    isCancelling = true
//                    onCancel()
//                }
        }
    }
}

#Preview {
    List {
        ScheduledTasksView.ScheduledTaskButton(
            task: TaskInfo(
                category: "test",
                currentProgressPercentage: nil,
                description: nil,
                id: "123",
                isHidden: false,
                key: "123",
                lastExecutionResult: TaskResult(
                    endTimeUtc: Date(timeIntervalSinceNow: -10),
                    errorMessage: nil,
                    id: nil,
                    key: nil,
                    longErrorMessage: nil,
                    name: nil,
                    startTimeUtc: Date(),
                    status: .completed
                ),
                name: "Test",
                state: .idle,
                triggers: nil
            ),
            onSelect: {},
            onCancel: {}
        )

        ScheduledTasksView.ScheduledTaskButton(
            task: TaskInfo(
                category: "test",
                currentProgressPercentage: nil,
                description: nil,
                id: "123",
                isHidden: false,
                key: "123",
                lastExecutionResult: TaskResult(
                    endTimeUtc: Date(timeIntervalSinceNow: -10),
                    errorMessage: nil,
                    id: nil,
                    key: nil,
                    longErrorMessage: nil,
                    name: nil,
                    startTimeUtc: Date(),
                    status: .cancelled
                ),
                name: "Test",
                state: .idle,
                triggers: nil
            ),
            onSelect: {},
            onCancel: {}
        )

        ScheduledTasksView.ScheduledTaskButton(
            task: TaskInfo(
                category: "test",
                currentProgressPercentage: 0.6,
                description: nil,
                id: "123",
                isHidden: false,
                key: "123",
                lastExecutionResult: TaskResult(
                    endTimeUtc: Date(timeIntervalSinceNow: -10),
                    errorMessage: nil,
                    id: nil,
                    key: nil,
                    longErrorMessage: nil,
                    name: nil,
                    startTimeUtc: Date(),
                    status: .cancelled
                ),
                name: "Test",
                state: .idle,
                triggers: nil
            ),
            onSelect: {},
            onCancel: {}
        )
    }
}
