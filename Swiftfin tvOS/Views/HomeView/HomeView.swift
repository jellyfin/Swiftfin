//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

struct HomeView: View {

    // MARK: - Defaults

    @Default(.Customization.Home.showRecentlyAdded)
    private var showRecentlyAdded

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: HomeCoordinator.Router

    @StateObject
    private var viewModel = HomeViewModel()

    // MARK: - Cinematic State

    @State
    private var isCinematic: Bool = true

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.clear
            switch viewModel.state {
            case .content:
                if viewModel.libraries.isEmpty {
                    ErrorView(
                        error: JellyfinAPIError(L10n.noValidLibrariesError)
                    )
                } else {
                    contentView
                }
            case let .error(error):
                ErrorView(error: error)
                    .onRetry {
                        viewModel.send(.refresh)
                    }
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .ignoresSafeArea(isCinematic ? .all : [])
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.refresh) {
                ProgressView()
            }
        }
        .sinceLastDisappear { interval in
            if interval > 60 || viewModel.notificationsReceived.contains(.itemMetadataDidChange) {
                viewModel.send(.backgroundRefresh)
                viewModel.notificationsReceived.remove(.itemMetadataDidChange)
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                ContinueWatchingView(viewModel: viewModel)

                NextUpView(
                    viewModel: viewModel.nextUpViewModel,
                    cinematic: viewModel.resumeItems.isEmpty
                )

                if showRecentlyAdded {
                    RecentlyAddedView(
                        viewModel: viewModel.recentlyAddedViewModel,
                        cinematic: viewModel.resumeItems.isEmpty
                            && viewModel.nextUpViewModel.elements.isEmpty
                    )
                }

                ForEach(viewModel.libraries.indices, id: \.self) { index in
                    LatestInLibraryView(viewModel: viewModel.libraries[index])
                }

                Divider()

                refreshButtonView
            }
        }
    }

    // MARK: - Refresh Button View

    private var refreshButtonView: some View {
        HStack {
            Spacer()
            PrimaryButton(title: L10n.refresh)
                .onSelect {
                    viewModel.send(.refresh)
                }
            Spacer()
        }
        .focusSection()
        .padding()
    }
}
