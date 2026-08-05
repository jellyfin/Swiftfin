//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: do something for errors from restart/shutdown
//       - toast?

struct ServerTasksView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = ServerTasksViewModel()

    // MARK: - Server Function Buttons

    @ViewBuilder
    private func destructiveServerTask(
        title: String,
        systemName: String,
        message: String,
        action: @escaping () -> Void
    ) -> some View {
        StateAdapter(initialValue: false) { isPresented in
            Button(role: .destructive) {
                isPresented.wrappedValue = true
            } label: {
                HStack {
                    Text(title)
                        .fontWeight(.semibold)

                    Spacer()

                    Image(systemName: systemName)
                        .fontWeight(.bold)
                }
            }
            .confirmationDialog(
                title,
                isPresented: isPresented,
                titleVisibility: .visible
            ) {
                Button(title, role: .destructive, action: action)
            } message: {
                Text(message)
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        List {

            ListTitleSection(
                L10n.tasks,
                description: L10n.tasksDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsTasks)
            }

            Section(L10n.server) {
                destructiveServerTask(
                    title: L10n.restartServer,
                    systemName: "arrow.clockwise",
                    message: L10n.restartWarning
                ) {
                    viewModel.restartApplication()
                }

                destructiveServerTask(
                    title: L10n.shutdownServer,
                    systemName: "power",
                    message: L10n.shutdownWarning
                ) {
                    viewModel.shutdownApplication()
                }
            }

            ForEach(viewModel.tasks.keys, id: \.self) { category in
                Section(category) {
                    ForEach(viewModel.tasks[category] ?? []) { task in
                        ServerTaskRow(observer: task)
                    }
                }
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            case .initial:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .navigationTitle(L10n.tasks)
        .refreshable {
            viewModel.refresh()
        }
        .onFirstAppear {
            viewModel.refresh()
        }
    }
}

// MARK: - Server Task Row

private struct ServerTaskRow: View {

    @CurrentDate
    private var currentDate: Date

    @Router
    private var router

    @ObservedObject
    var observer: ServerTaskObserver

    private var isRunning: Bool {
        observer.task.state == .running
    }

    @ViewBuilder
    private var taskResultView: some View {
        if isRunning {
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
                .fontWeight(.semibold)
            }
        }
    }

    var body: some View {
        Button {
            router.route(to: .editServerTask(observer: observer))
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {

                    Text(observer.task.name ?? L10n.unknown)
                        .fontWeight(.semibold)

                    taskResultView
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isRunning {
                    ProgressView(value: (observer.task.currentProgressPercentage ?? 0) / 100)
                        .progressViewStyle(.gauge)
                        .transition(.opacity.combined(with: .scale).animation(.bouncy))
                        .frame(width: 25, height: 25)
                }

                Image(systemName: "chevron.right")
                    .font(.body.weight(.regular))
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.linear(duration: 0.1), value: isRunning)
        .foregroundStyle(.primary, .secondary)
    }
}
