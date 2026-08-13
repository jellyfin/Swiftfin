//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ServerTasksView {

    struct ServerTaskRow: View {

        @CurrentDate
        private var currentDate: Date

        @Router
        private var router

        @ObservedObject
        var viewModel: TaskViewModel

        private var isRunning: Bool {
            viewModel.task.state == .running
        }

        private var contentView: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {

                    Text(viewModel.task.name ?? L10n.unknown)
                        .fontWeight(.semibold)

                    switch viewModel.task.state {
                    case .idle:
                        Group {
                            if let taskEndTime = viewModel.task.lastExecutionResult?.endTimeUtc {
                                Text(
                                    L10n.lastRunTime(
                                        Date.RelativeFormatStyle(
                                            presentation: .numeric,
                                            unitsStyle: .narrow
                                        )
                                        .format(taskEndTime)
                                    )
                                )
                                .id(currentDate)
                                .monospacedDigit()
                            } else {
                                Text(L10n.neverRun)
                            }
                        }
                        .foregroundStyle(.secondary)

                        if let status = viewModel.task.lastExecutionResult?.status, status != .completed {
                            Label(
                                status.displayTitle,
                                systemImage: "exclamationmark.circle.fill"
                            )
                            .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                            .foregroundStyle(.orange)
                            .fontWeight(.semibold)
                        }
                    default:
                        Text(viewModel.task.state?.displayTitle)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)

                Spacer()

                if isRunning {
                    ProgressView(value: (viewModel.task.currentProgressPercentage ?? 0) / 100)
                        .progressViewStyle(.gauge)
                        .transition(.opacity.combined(with: .scale).animation(.bouncy))
                        .frame(width: 25, height: 25)
                }
            }
        }

        var body: some View {
            ChevronButton {
                router.route(to: .taskDetails(viewModel: viewModel))
            } label: {
                contentView
            }
            .animation(.linear(duration: 0.1), value: isRunning)
            .foregroundStyle(.primary, .secondary)
        }
    }
}
