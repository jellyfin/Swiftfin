//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Stinsen
import SwiftUI

extension ScheduledTasksView {

    struct ScheduledTaskButton: View {

        @CurrentDate
        private var currentDate: Date

        @EnvironmentObject
        private var router: SettingsCoordinator.Router

        @ObservedObject
        var observer: ServerTaskObserver

        @State
        private var isPresentingConfirmation = false

        // MARK: - Task Details Section

        @ViewBuilder
        private var taskView: some View {
            VStack(alignment: .leading, spacing: 4) {

                Text(observer.task.name ?? L10n.unknown)
                    .fontWeight(.semibold)

                taskResultView
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }

        // MARK: - Task Status Section

        @ViewBuilder
        private var statusView: some View {
            switch observer.state {
            case .running:
                ProgressView(value: (observer.task.currentProgressPercentage ?? 0) / 100)
                    .progressViewStyle(.gauge(systemImage: "stop.fill"))
                    .transition(.opacity.combined(with: .scale).animation(.bouncy))
            default:
                Image(systemName: "play.fill")
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .scale).animation(.bouncy))
            }
        }

        // MARK: - Task Status View

        @ViewBuilder
        private var taskResultView: some View {
            if observer.state == .running {
                Text(L10n.running)
            } else if observer.task.state == .cancelling {
                Text(L10n.cancelling)
            } else {
                if let taskEndTime = observer.task.lastExecutionResult?.endTimeUtc {
                    Text(L10n.lastRunTime(Date.RelativeFormatStyle(presentation: .numeric, unitsStyle: .narrow).format(taskEndTime)))
                        .id(currentDate)
                        .monospacedDigit()
                } else {
                    Text(L10n.neverRun)
                }

                if let status = observer.task.lastExecutionResult?.status, status != .completed {
                    Label(
                        status.displayTitle,
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                    .foregroundStyle(.orange)
                    .backport
                    .fontWeight(.semibold)
                }
            }
        }

        @ViewBuilder
        var body: some View {
            Button {
                isPresentingConfirmation = true
            } label: {
                HStack {
                    taskView

                    Spacer()

                    statusView
                        .frame(width: 25, height: 25)
                }
            }
            .animation(.linear(duration: 0.1), value: observer.state)
            .foregroundStyle(.primary, .secondary)
            .confirmationDialog(
                observer.task.name ?? .emptyDash,
                isPresented: $isPresentingConfirmation,
                titleVisibility: .visible
            ) {
                Group {
                    if observer.state == .running {
                        Button(L10n.stop) {
                            observer.send(.stop)
                        }
                    } else {
                        Button(L10n.run) {
                            observer.send(.start)
                        }
                    }
                }
                .disabled(observer.task.state == .cancelling)

                Button(L10n.edit) {
                    router.route(to: \.editScheduledTask, observer)
                }
            } message: {
                if let description = observer.task.description {
                    Text(description)
                }
            }
        }
    }
}
