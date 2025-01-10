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

extension HomeView {

    struct LatestInLibraryView: View {

        // MARK: - Defaults

        @Default(.Customization.latestInLibraryPosterType)
        private var posterType

        // MARK: - Observed & Environment Objects

        @EnvironmentObject
        private var router: HomeCoordinator.Router

        @ObservedObject
        var viewModel: LatestInLibraryViewModel

        // MARK: - Body

        var body: some View {
            ZStack {
                switch viewModel.state {
                case .content:
                    if viewModel.elements.isNotEmpty {
                        contentView
                    }
                case let .error(error):
                    ErrorView(error: error)
                        .onRetry {
                            viewModel.send(.refresh)
                        }
                case .initial, .refreshing:
                    LoadingView(
                        title: L10n.latestWithString(viewModel.parent?.displayTitle ?? .emptyDash),
                        posterType: posterType
                    )
                }
            }
            .animation(.linear(duration: 0.1), value: viewModel.state)
            .ignoresSafeArea()
        }

        // MARK: - Content View

        @ViewBuilder
        var contentView: some View {
            PosterHStack(
                title: L10n.latestWithString(viewModel.parent?.displayTitle ?? .emptyDash),
                type: posterType,
                items: viewModel.elements
            )
            .onSelect { item in
                router.route(to: \.item, item)
            }
        }
    }
}
