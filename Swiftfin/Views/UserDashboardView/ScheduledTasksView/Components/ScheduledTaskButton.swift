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
        var taskID: String
        var taskName: String
        var taskLastStartTime: Date?
        var taskLastEndTime: Date?
        var taskLastStatus: TaskCompletionStatus?
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
                "Are you sure you want to run '\(taskName.localizedCapitalized)'?",
                isPresented: $showConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.confirm) {
                    onSelect()
                    isStarting = true
                }
            }
            .onChange(of: taskLastStartTime) { _ in
                isStarting = false
            }
        }

        // MARK: Task Details Section

        @ViewBuilder
        private var taskView: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(taskName.localizedCapitalized)
                    .foregroundColor(.primary)
                if (progress == nil || progress == 100 || progress == 0) && !isStarting {
                    lastRanTextView
                        .foregroundColor(.secondary)
                    if let taskLastStartTime,
                       let taskLastEndTime
                    {
                        HStack {
                            getRunDuration(
                                startDate: taskLastStartTime,
                                endDate: taskLastEndTime
                            )
                            .foregroundColor(.secondary)
                            .font(.footnote)
                            if let taskLastStatus {
                                Text(taskLastStatus.rawValue)
                                    .foregroundColor(getStatusColor(taskStatus: taskLastStatus))
                                    .font(.footnote)
                            }
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

        private var lastRanTextView: some View {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            if let taskLastEndTime {
                return Text("Last ran \(formatter.localizedString(for: taskLastEndTime, relativeTo: Date()))")
            }
            return Text("Last ran never.")
        }

        // MARK: Ran for X Minutes View

        private func getRunDuration(startDate: Date, endDate: Date) -> some View {
            let duration = endDate.timeIntervalSince(startDate)
            let minutes = Int(duration / 60)
            let hours = Int(minutes / 60)
            let remainingMinutes = minutes % 60

            if hours > 0 {
                return Text("Ran for \(hours) hour(s) and \(remainingMinutes) minute(s)")
            } else {
                return Text("Ran for \(minutes) minute(s)")
            }
        }

        private func getStatusColor(taskStatus: TaskCompletionStatus) -> Color {
            switch taskStatus {
            case .completed:
                return .green
            case .failed:
                return .red
            case .aborted:
                return .yellow
            case .cancelled:
                return .blue
            }
        }
    }
}
