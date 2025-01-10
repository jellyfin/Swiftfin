//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

// TODO: filter for streaming/inactive

struct ActiveSessionsView: View {

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @StateObject
    private var viewModel = ActiveSessionsViewModel()

    private let timer = Timer.publish(every: 5, on: .main, in: .common)
        .autoconnect()

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.sessions.isEmpty {
            L10n.noResults.text
        } else {
            CollectionVGrid(
                uniqueElements: viewModel.sessions.keys,
                id: \.self,
                layout: .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
            ) { id in
                ActiveSessionRow(box: viewModel.sessions[id]!) {
                    router.route(
                        to: \.activeDeviceDetails,
                        viewModel.sessions[id]!
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.refreshSessions)
            }
    }

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        ZStack {
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
        .navigationTitle(L10n.sessions)
        .onFirstAppear {
            viewModel.send(.refreshSessions)
        }
        .onReceive(timer) { _ in
            viewModel.send(.getSessions)
        }
        .refreshable {
            viewModel.send(.refreshSessions)
        }
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.gettingSessions) {
                ProgressView()
            }
        }
    }
}
