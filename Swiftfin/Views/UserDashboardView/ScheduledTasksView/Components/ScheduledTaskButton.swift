//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ScheduledTasksView {
    struct ScheduledTaskButton: View {
        var task: TaskInfo
        var progress: Double?
        var onSelect: () -> Void
        var onCancel: () -> Void

        @State
        private var isCancelling = false
        @State
        private var isStarting = false
        @State
        private var showConfirmation = false

        // MARK: Body

        @ViewBuilder
        var body: some View {
            Button(action: {
                isCancelling = false
                showConfirmation = true
            }) {
                HStack {
                    taskView
                    Spacer()
                    statusView
                }
            }
            .confirmationDialog(
                """
                \(task.name?.localizedCapitalized ?? L10n.unknown)
                \(task.lastExecutionResult?.longErrorMessage ?? "")
                """,
                isPresented: $showConfirmation,
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

        // MARK: Task Details Section

        @ViewBuilder
        private var taskView: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name?.localizedCapitalized ?? L10n.unknown)
                    .foregroundColor(.primary)
                if (progress == nil || progress == 100 || progress == 0) && !isStarting {
                    lastRanView
                        .foregroundColor(.secondary)
                    if let taskStatus = task.lastExecutionResult?.status {
                        if taskStatus == .completed {
                            Text(taskStatus.rawValue)
                                .foregroundColor(.green)
                        } else {
                            Label(
                                taskStatus.rawValue,
                                systemImage: "exclamationmark.circle.fill"
                            )
                            .foregroundColor(.yellow)
                        }
                    }
                } else {
                    Text("Running...")
                }
            }
        }

        // MARK: Task Status Section

        @ViewBuilder
        private var statusView: some View {
            if let progress = progress,
               (progress > 0 && progress < 100) || isStarting
            {
                if isCancelling {
                    Text(L10n.canceled)
                        .foregroundColor(.red)

                } else {
                    Text(
                        NumberFormatter.localizedString(
                            from: NSNumber(
                                value: progress / 100
                            ),
                            number: .percent
                        )
                    )
                    .foregroundColor(.secondary)

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.horizontal, 8)

                    Image(systemName: "x.circle")
                        .foregroundColor(.red)
                        .onTapGesture {
                            isCancelling = true
                            onCancel()
                        }
                }
            } else {
                Image(systemName: "play.fill")
                    .foregroundColor(.secondary)
            }
        }

        // MARK: Last Ran X Minutes Ago View

        private var lastRanView: some View {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            if let taskEndTime = task.lastExecutionResult?.endTimeUtc {
                return Text("Last ran \(formatter.localizedString(for: taskEndTime, relativeTo: Date()))")
            }
            return Text("Last ran never.")
        }
    }
}
