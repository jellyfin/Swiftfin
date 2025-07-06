//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import SwiftUI

// TODO: seems to redraw view when popped to sometimes?
//       - similar to MediaView TODO bug?
//       - indicated by snapping to the top
struct HomeView: View {

    @Default(.Customization.nextUpPosterType)
    private var nextUpPosterType
    @Default(.Customization.Home.showRecentlyAdded)
    private var showRecentlyAdded
    @Default(.Customization.recentlyAddedPosterType)
    private var recentlyAddedPosterType

    @Router
    private var router

    @StateObject
    private var viewModel = HomeViewModel()

    @Injected(\.networkMonitor)
    private var networkMonitor

    @EnvironmentObject
    private var rootCoordinator: RootCoordinator

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {

                ContinueWatchingView(viewModel: viewModel)

                NextUpView(viewModel: viewModel.nextUpViewModel)
                    .onSetPlayed { item in
                        viewModel.send(.setIsPlayed(true, item))
                    }

                if showRecentlyAdded {
                    RecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)
                }

                ForEach(viewModel.libraries) { viewModel in
                    LatestInLibraryView(viewModel: viewModel)
                }
            }
            .edgePadding(.vertical)
        }
        .refreshable {
            viewModel.send(.refresh)
        }
    }

    private func errorView(with error: some Error) -> some View {
        VStack(spacing: 20) {
            ErrorView(error: error)
                .onRetry {
                    viewModel.send(.refresh)
                }

            if !networkMonitor.isConnected {
                Button {
                    rootCoordinator.root(.downloads)
                } label: {
                    Label("View Downloads", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: 300)
            }
        }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                errorView(with: error)
            case .initial, .refreshing:
                DelayedProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .navigationTitle(L10n.home)
        .topBarTrailing {

            if viewModel.backgroundStates.contains(.refresh) {
                ProgressView()
            }

            SettingsBarButton(
                server: viewModel.userSession.server,
                user: viewModel.userSession.user
            ) {
                router.route(to: .settings)
            }
        }
        .sinceLastDisappear { interval in
            if interval > 60 || viewModel.notificationsReceived.contains(.itemMetadataDidChange) {
                viewModel.send(.backgroundRefresh)
                viewModel.notificationsReceived.remove(.itemMetadataDidChange)
            }
        }
    }
}
