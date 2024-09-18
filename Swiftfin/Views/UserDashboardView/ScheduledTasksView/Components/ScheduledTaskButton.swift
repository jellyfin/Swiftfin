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
        var task: TaskInfo
        var progress: Double?
        var onSelect: () -> Void
        var onCancel: () -> Void

        // MARK: - Tracked States

        @State
        private var isCancelling = false
        @State
        private var isStarting = false
        @State
        private var showConfirmation = false

        // MARK: - Body

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
                confirmationDialogText,
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

        // MARK: - Task Details Section

        @ViewBuilder
        private var taskView: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name?.localizedCapitalized ?? L10n.unknown)
                    .foregroundColor(.primary)
                if !isActive {
                    lastRanView
                    taskStatusView
                } else {
                    Text("Running...")
                }
            }
        }

        // MARK: - Task Status Section

        @ViewBuilder
        private var statusView: some View {
            if isActive {
                if isCancelling {
                    Text(L10n.canceled)
                        .foregroundColor(.red)
                } else {
                    progressView(progress: progress)
                    cancelButton
                }
            } else {
                playButton
            }
        }

        // MARK: - Last Ran View

        private var lastRanView: some View {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            if let taskEndTime = task.lastExecutionResult?.endTimeUtc {
                return Text("Last ran \(formatter.localizedString(for: taskEndTime, relativeTo: Date()))")
                    .foregroundColor(.secondary)
            }
            return Text("Last ran never.")
                .foregroundColor(.secondary)
        }

        // MARK: - Task Status View

        @ViewBuilder
        private var taskStatusView: some View {
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
        }

        // MARK: - Task is Active

        private var isActive: Bool {
            ((progress ?? 0) > 0 && (progress ?? 0) < 100) || isStarting
        }

        // MARK: - Task Confirmation

        private var confirmationDialogText: String {
            """
            \(task.name?.localizedCapitalized ?? L10n.unknown)
            \(task.lastExecutionResult?.longErrorMessage ?? "")
            """
        }

        // MARK: - Cancel Button

        private var cancelButton: some View {
            Image(systemName: "x.circle")
                .foregroundColor(.red)
                .onTapGesture {
                    isCancelling = true
                    onCancel()
                }
        }

        // MARK: - Play Button

        private var playButton: some View {
            Image(systemName: "play.fill")
                .foregroundColor(.secondary)
        }

        // MARK: - Progress View

        private func progressView(progress: Double?) -> some View {
            HStack {
                Text(
                    NumberFormatter.localizedString(
                        from: NSNumber(value: (progress ?? 0) / 100),
                        number: .percent
                    )
                )
                .foregroundColor(.secondary)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.horizontal, 8)
            }
        }
    }
}
