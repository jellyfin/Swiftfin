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

        // MARK: - Libary Cinematic Background

        let cinematic: Bool

        // MARK: - Cinematic Image Source

        private func cinematicImageSource(for item: BaseItemDto) -> ImageSource {
            item.imageSource(
                .logo,
                maxWidth: UIScreen.main.bounds.width * 0.4,
                maxHeight: 200
            )
        }

        // MARK: - Body

        var body: some View {
            ZStack {
                switch viewModel.state {
                case .content:
                    if viewModel.elements.isNotEmpty {
                        switch cinematic {
                        case true:
                            cinematicView
                        case false:
                            standardView
                        }
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
        }

        // MARK: - Cinematic View

        @ViewBuilder
        var cinematicView: some View {
            CinematicItemSelector(
                items: viewModel.elements.elements,
                type: posterType
            )
            .topContent { item in
                ImageView(cinematicImageSource(for: item))
                    .placeholder { _ in
                        EmptyView()
                    }
                    .failure {
                        Text(item.displayTitle)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                    }
                    .edgePadding(.leading)
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200, alignment: .bottomLeading)
            }
            .onSelect { item in
                router.route(to: \.item, item)
            }
        }

        // MARK: - Standard View

        @ViewBuilder
        var standardView: some View {
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
