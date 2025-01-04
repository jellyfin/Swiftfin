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

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.clear
            switch viewModel.state {
            case .content:
                if viewModel.libraries.isEmpty {
                    ErrorView(
                        error: JellyfinAPIError(
                            L10n.noValidLibrariesError
                        )
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
        .ignoresSafeArea()
        .onFirstAppear {
            viewModel.send(.refresh)
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

                if !viewModel.resumeItems.isEmpty {
                    ResumeView(viewModel: viewModel)
                }

                if !viewModel.nextUpViewModel.elements.isEmpty {
                    NextUpView(
                        viewModel: viewModel.nextUpViewModel,
                        cinematic: viewModel.resumeItems.isEmpty
                    )
                }

                if showRecentlyAdded && !viewModel.recentlyAddedViewModel.elements.isEmpty {
                    RecentlyAddedView(
                        viewModel: viewModel.recentlyAddedViewModel,
                        cinematic: viewModel.resumeItems.isEmpty &&
                            viewModel.nextUpViewModel.elements.isEmpty
                    )
                }

                ForEach(viewModel.libraries.indices, id: \.self) { index in
                    LatestInLibraryView(
                        viewModel: viewModel.libraries[index],
                        cinematic: viewModel.resumeItems.isEmpty &&
                            viewModel.nextUpViewModel.elements.isEmpty &&
                            (!showRecentlyAdded || viewModel.recentlyAddedViewModel.elements.isEmpty) &&
                            index == 0
                    )
                }

                Divider()

                refreshButtonView
            }
        }
    }

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
