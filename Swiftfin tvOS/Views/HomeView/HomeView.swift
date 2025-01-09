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

    // MARK: - Cinematic Row

    private enum CinematicRow {
        case resume
        case nextUp
        case recentlyAdded
        case library
        case none
    }

    // MARK: - Defaults

    @Default(.Customization.Home.showRecentlyAdded)
    private var showRecentlyAdded

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: HomeCoordinator.Router

    @StateObject
    private var viewModel = HomeViewModel()

    // MARK: - Conditional Content Validation

    private var hasResumeContent: Bool {
        viewModel.resumeItems.isNotEmpty
    }

    private var hasNextUpContent: Bool {
        viewModel.nextUpViewModel.elements.isNotEmpty
    }

    private var hasRecentContent: Bool {
        viewModel.recentlyAddedViewModel.elements.isNotEmpty && showRecentlyAdded
    }

    // MARK: - Active Libraries

    private var activeLibraries: [LatestInLibraryViewModel] {
        viewModel.libraries.filter(\.elements.isNotEmpty)
    }

    // MARK: - Conditional Cinematic Row

    private var cinematicRow: CinematicRow {
        if hasResumeContent {
            return .resume
        } else if hasNextUpContent {
            return .nextUp
        } else if hasRecentContent {
            return .recentlyAdded
        } else if activeLibraries.isNotEmpty {
            return .library
        } else {
            return .none
        }
    }

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
        .ignoresSafeArea()
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
                conditionalContentView
                libraryContentView
                Divider()
                refreshButtonView
            }
        }
    }

    // MARK: - Conditional Content View

    @ViewBuilder
    private var conditionalContentView: some View {
        switch cinematicRow {
        case .resume:
            ResumeView(viewModel: viewModel)
            NextUpView(viewModel: viewModel.nextUpViewModel)
            RecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)

        case .nextUp:
            NextUpView(viewModel: viewModel.nextUpViewModel, cinematic: true)
            RecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)

        case .recentlyAdded:
            RecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel, cinematic: true)

        case .library:
            EmptyView()

        case .none, _:
            Spacer()
        }
    }

    // MARK: - Library Content View

    @ViewBuilder
    private var libraryContentView: some View {
        ForEach(activeLibraries.indices, id: \.self) { index in
            LatestInLibraryView(
                viewModel: activeLibraries[index],
                cinematic: index == 0 && cinematicRow == .library
            )
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
