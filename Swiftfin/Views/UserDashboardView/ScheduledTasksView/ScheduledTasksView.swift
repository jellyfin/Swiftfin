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

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
        Button(role: .destructive) {
            showRestartConfirmation = true
        } label: {
            HStack {
                L10n.restartServer.text
                Spacer()
                Image(systemName: "arrow.clockwise.circle")
            }
        }
        .confirmationDialog(
            L10n.restartWarning,
            isPresented: $showRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.restartServer, role: .destructive) {
                viewModel.send(.restartApplication)
            }
        }

        Button(role: .destructive) {
            showShutdownConfirmation = true
        } label: {
            HStack {
                L10n.shutdownServer.text
                Spacer()
                Image(systemName: "power.circle")
            }
        }
        .confirmationDialog(
            L10n.shutdownWarning,
            isPresented: $showShutdownConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.shutdownServer, role: .destructive) {
                viewModel.send(.shutdownApplication)
            }
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
                        taskID: taskID,
                        taskName: taskName,
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
