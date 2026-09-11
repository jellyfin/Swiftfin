//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import JellyfinAPI
import SwiftUI

// TODO: do something for errors from restart/shutdown
//       - toast?

struct ServerTasksView: View {

    @StateObject
    private var viewModel = ServerTasksViewModel()

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
                        ServerTaskRow(viewModel: task)
                    }
                }
            }
        }
    }

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
                        .frame(maxWidth: .infinity, alignment: .leading)

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
