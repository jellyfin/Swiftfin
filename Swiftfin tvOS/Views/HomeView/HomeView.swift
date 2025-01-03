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
    private var viewModel: HomeViewModel = {
        let viewModel = HomeViewModel()
        viewModel.send(.refresh)
        return viewModel
    }()

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.clear
            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
                    .onRetry {
                        viewModel.send(.refresh)
                    }
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .transition(.opacity.animation(.linear(duration: 0.2)))
        .ignoresSafeArea()
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

                ResumeView(viewModel: viewModel)

                NextUpView(
                    viewModel: viewModel.nextUpViewModel,
                    cinematic: viewModel.resumeItems.isEmpty
                )

                if showRecentlyAdded {
                    RecentlyAddedView(
                        viewModel: viewModel.recentlyAddedViewModel,
                        cinematic: viewModel.nextUpViewModel.elements.isEmpty
                            && viewModel.resumeItems.isEmpty
                    )
                }

                ForEach(viewModel.libraries.indices, id: \.self) { index in
                    LatestInLibraryView(
                        viewModel: viewModel.libraries[index],
                        cinematic: index == 0
                            && (viewModel.recentlyAddedViewModel.elements.isEmpty || !showRecentlyAdded)
                            && viewModel.nextUpViewModel.elements.isEmpty
                            && viewModel.resumeItems.isEmpty
                    )
                }
            }
        }
    }
}
