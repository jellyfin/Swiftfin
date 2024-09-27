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

struct ScheduledTasksView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @State
    private var isPresentingRestartConfirmation = false
    @State
    private var isPresentingShutdownConfirmation = false

    @StateObject
    private var viewModel = ScheduledTasksViewModel()

    private let timer = Timer.publish(every: 5, on: .main, in: .common)
        .autoconnect()

    // MARK: - Server Function Buttons

    @ViewBuilder
    private var serverFunctions: some View {
        ServerTaskButton(
            title: L10n.restartServer,
            systemImage: "arrow.clockwise",
            warningMessage: L10n.restartWarning,
            isPresented: $isPresentingRestartConfirmation
        ) {
            viewModel.send(.restartApplication)
        }

        ServerTaskButton(
            title: L10n.shutdownServer,
            systemImage: "power",
            warningMessage: L10n.shutdownWarning,
            isPresented: $isPresentingShutdownConfirmation
        ) {
            viewModel.send(.shutdownApplication)
        }
    }

    // MARK: - Section for Category

    @ViewBuilder
    private func taskSection(for category: String, tasks: [TaskInfo]) -> some View {
        if tasks.isNotEmpty {
            Section(category) {
                ForEach(tasks) { task in
                    ScheduledTaskButton(
                        task: task
                    ) {
                        viewModel.send(.startTask(task.id!))
                    } onCancel: {
                        viewModel.send(.stopTask(task.id!))
                    }
                }
            }
        }
    }

    // MARK: - Body

    @ViewBuilder
    private var contentView: some View {
        List {
            Section(L10n.server) {
                serverFunctions
            }

            if viewModel.tasks.isNotEmpty {
                ForEach(viewModel.tasks.keys, id: \.self) { category in
                    taskSection(for: category, tasks: viewModel.tasks[category] ?? [])
                }
            }
        }
    }

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.fetchTasks)
            }
    }

    var body: some View {
        ZStack {
            Color.clear

            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                errorView(with: error)
            case .initial:
                DelayedProgressView()
            }
        }
        .navigationTitle(L10n.scheduledTasks)
        .topBarTrailing {
//            if viewModel.background
        }
        .onFirstAppear {
            viewModel.send(.fetchTasks)
        }
        .onReceive(timer) { _ in
            viewModel.send(.fetchTasks)
        }
    }
}
