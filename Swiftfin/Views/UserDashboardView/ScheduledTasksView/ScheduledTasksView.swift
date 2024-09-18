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
    private var showRestartConfirmation = false
    @State
    private var showShutdownConfirmation = false

    @StateObject
    private var viewModel = ScheduledTasksViewModel()

    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    // MARK: Current User

    private var scheduledTasks: [TaskInfo] {
        viewModel.tasks
    }

    // MARK: Body

    var body: some View {
        List {
            Section(L10n.server) {
                primaryFunctions
            }

            if scheduledTasks.isEmpty {
                Text(L10n.none)
            } else {
                secondaryFunctions
            }
        }
        .navigationTitle(L10n.scheduledTasks)
        .onAppear {
            viewModel.send(.fetchTasks)
        }
        .refreshable {
            viewModel.send(.fetchTasks)
        }
        .onReceive(timer) { _ in
            viewModel.send(.backgroundRefresh)
        }
    }

    // MARK: Admin Function buttons

    @ViewBuilder
    private var primaryFunctions: some View {
        ServerTaskButton(
            label: L10n.restartServer,
            icon: "arrow.clockwise.circle",
            warningMessage: L10n.restartWarning,
            isPresented: $showRestartConfirmation
        ) {
            viewModel.send(.restartApplication)
        }

        ServerTaskButton(
            label: L10n.shutdownServer,
            icon: "power.circle",
            warningMessage: L10n.shutdownWarning,
            isPresented: $showShutdownConfirmation
        ) {
            viewModel.send(.shutdownApplication)
        }
    }

    @ViewBuilder
    private var secondaryFunctions: some View {
        let groupedTasks = Dictionary(grouping: scheduledTasks, by: { $0.category ?? "" })

        ForEach(groupedTasks.keys.sorted(), id: \.self) { category in
            sectionForCategory(category, tasks: groupedTasks[category] ?? [])
        }
    }

    @ViewBuilder
    private func sectionForCategory(_ category: String, tasks: [TaskInfo]) -> some View {
        Section(header: Text(category)) {
            ForEach(tasks, id: \.id) { task in
                if let taskName = task.name,
                   let taskID = task.id
                {
                    ScheduledTaskButton(
                        task: task,
                        progress: viewModel.progress[taskID],
                        onSelect: {
                            viewModel.send(.startTask(taskID))
                        }, onCancel: {
                            viewModel.send(.stopTask(taskID))
                        }
                    )
                }
            }
        }
    }
}
