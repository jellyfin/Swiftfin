//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension HomeView {

    struct ContentView: View {

        @EnvironmentObject
        private var router: HomeCoordinator.Router
        @ObservedObject
        var viewModel: HomeViewModel

        private func itemSelectorImageSource(for item: BaseItemDto) -> ImageSource {
            if item.type == .episode {
                return item.seriesImageSource(
                    .logo,
                    maxWidth: UIScreen.main.bounds.width * 0.4,
                    maxHeight: 200
                )
            } else {
                return item.imageSource(
                    .logo,
                    maxWidth: UIScreen.main.bounds.width * 0.4,
                    maxHeight: 200
                )
            }
        }

        @ViewBuilder
        private var cinematicResumeItems: some View {
            CinematicItemSelector(items: viewModel.resumeItems)
                .topContent { item in
                    ImageView(itemSelectorImageSource(for: item))
                        .resizingMode(.bottomLeft)
                        .placeholder {
                            EmptyView()
                        }
                        .failure {
                            Text(item.displayName)
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                        }
                        .padding2(.leading)
                }
                .content { item in
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .itemImageOverlay { item in
                    LandscapePosterProgressBar(
                        title: item.progress ?? L10n.continue,
                        progress: (item.userData?.playedPercentage ?? 0) / 100
                    )
                }
                .onSelect { item in
                    router.route(to: \.item, item)
                }
        }

        @ViewBuilder
        private var cinematicLatestAddedItems: some View {
            CinematicItemSelector(items: viewModel.latestAddedItems)
                .topContent { item in
                    ImageView(itemSelectorImageSource(for: item))
                        .resizingMode(.bottomLeft)
                        .placeholder {
                            EmptyView()
                        }
                        .failure {
                            Text(item.displayName)
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                        }
                        .padding2(.leading)
                }
                .onSelect { item in
                    router.route(to: \.item, item)
                }
        }

        var body: some View {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if viewModel.resumeItems.isEmpty {
                        cinematicLatestAddedItems

                        if !viewModel.nextUpItems.isEmpty {
                            PosterHStack(title: L10n.nextUp, type: .portrait, items: viewModel.nextUpItems)
                                .onSelect { item in
                                    router.route(to: \.item, item)
                                }
                        }
                    } else {
                        cinematicResumeItems

                        if !viewModel.nextUpItems.isEmpty {
                            PosterHStack(title: L10n.nextUp, type: .portrait, items: viewModel.nextUpItems)
                                .onSelect { item in
                                    router.route(to: \.item, item)
                                }
                        }

                        if !viewModel.latestAddedItems.isEmpty {
                            PosterHStack(title: L10n.recentlyAdded, type: .portrait, items: viewModel.latestAddedItems)
                                .onSelect { item in
                                    router.route(to: \.item, item)
                                }
                        }
                    }

                    ForEach(viewModel.libraries, id: \.self) { library in
                        LatestInLibraryView(viewModel: LatestMediaViewModel(library: library))
                    }
                }
            }
        }
    }
}
