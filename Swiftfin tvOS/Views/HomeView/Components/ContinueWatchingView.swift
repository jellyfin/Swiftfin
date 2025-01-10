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

    struct ContinueWatchingView: View {

        // MARK: - Defaults

        @Default(.Customization.resumePosterType)
        private var posterType

        // MARK: - Observed & Environment Objects

        @EnvironmentObject
        private var router: HomeCoordinator.Router

        @ObservedObject
        var viewModel: HomeViewModel

        // MARK: - Cinematic Image Source

        private func cinematicImageSource(for item: BaseItemDto) -> ImageSource {
            if item.type == .episode {
                return item.seriesImageSource(
                    .logo,
                    maxWidth: 800,
                    maxHeight: 200
                )
            } else {
                return item.imageSource(
                    .logo,
                    maxWidth: 800,
                    maxHeight: 200
                )
            }
        }

        // MARK: - Body

        var body: some View {
            ZStack {
                switch viewModel.state {
                case .content:
                    if viewModel.resumeItems.isNotEmpty {
                        contentView
                    }
                case let .error(error):
                    ErrorView(error: error)
                        .onRetry {
                            viewModel.send(.refresh)
                        }
                case .initial, .refreshing:
                    LoadingView(
                        title: L10n.resume,
                        cinematic: true,
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
            CinematicItemSelector(
                items: viewModel.resumeItems.elements,
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
            .content { item in
                // TODO: clean up
                if item.type == .episode {
                    PosterButton<BaseItemDto>.EpisodeContentSubtitleContent.Subtitle(item: item)
                } else {
                    Text(" ")
                }
            }
            .contextMenu { item in
                Button {
                    viewModel.send(.setIsPlayed(true, item))
                } label: {
                    Label(L10n.played, systemImage: "checkmark.circle")
                }

                Button(role: .destructive) {
                    viewModel.send(.setIsPlayed(false, item))
                } label: {
                    Label(L10n.unplayed, systemImage: "minus.circle")
                }
            }
            .itemImageOverlay { item in
                LandscapePosterProgressBar(
                    title: item.progressLabel ?? L10n.continue,
                    progress: (item.userData?.playedPercentage ?? 0) / 100
                )
            }
            .onSelect { item in
                router.route(to: \.item, item)
            }
        }
    }
}
