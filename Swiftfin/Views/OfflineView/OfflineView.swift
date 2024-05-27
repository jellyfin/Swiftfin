//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import SwiftUI

struct OfflineView: View {

    @Default(.Customization.nextUpPosterType)
    private var nextUpPosterType
    @Default(.Customization.recentlyAddedPosterType)
    private var recentlyAddedPosterType

    @EnvironmentObject
    private var mainRouter: MainCoordinator.Router
    @EnvironmentObject
    private var router: HomeCoordinator.Router

    @ObservedObject
    var viewModel: OfflineViewModel

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {

                OfflineContinueWatchingView(viewModel: viewModel)

                OfflineNextUpView(offlineViewModel: viewModel)

                ForEach(viewModel.libraries) { model in
                    OfflineLibraryView(viewModel: model, offlineViewModel: viewModel)
                }
            }
            .edgePadding(.vertical)
        }
        .refreshable {
            viewModel.send(.refresh)
        }
    }

    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.refresh)
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
        .onAppear {
            viewModel.send(.refresh)
        }
        .navigationTitle(L10n.downloads)
        .topBarTrailing {

            if viewModel.backgroundStates.contains(.refresh) {
                ProgressView()
            }

            SettingsBarButton(
                server: viewModel.userSession.server,
                user: viewModel.userSession.user
            ) {
                mainRouter.route(to: \.settings)
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
