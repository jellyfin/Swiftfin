//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

// TODO: refactor after socket implementation

struct ServerTasksView: View {

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @StateObject
    private var viewModel = ServerTasksViewModel()

    private let timer = Timer.publish(every: 5, on: .main, in: .common)
        .autoconnect()

    // MARK: - Server Function Buttons

    @ViewBuilder
    private var serverFunctions: some View {
        DestructiveServerTask(
            title: L10n.restartServer,
            systemName: "arrow.clockwise",
            message: L10n.restartWarning
        ) {
            viewModel.send(.restartApplication)
        }

        DestructiveServerTask(
            title: L10n.shutdownServer,
            systemName: "power",
            message: L10n.shutdownWarning
        ) {
            viewModel.send(.shutdownApplication)
        }
    }

    // MARK: - Body

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
                serverFunctions
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

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.refreshTasks)
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
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .navigationTitle(L10n.tasks)
        .onFirstAppear {
            viewModel.send(.refreshTasks)
        }
        .onReceive(timer) { _ in
            viewModel.send(.getTasks)
        }
    }
}
