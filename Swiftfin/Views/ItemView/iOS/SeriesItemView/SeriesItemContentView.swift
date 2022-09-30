//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension SeriesItemView {

    struct ContentView: View {

        @EnvironmentObject
        private var mainRouter: MainCoordinator.Router
        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: SeriesItemViewModel
        @ScaledMetric
        private var staticOverviewHeight: CGFloat = 50

        var body: some View {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Episodes

                ItemHStackSwitcher(
                    type: .landscape,
                    manager: viewModel,
                    singleImage: true
                )
                .scaleItems(1.2)
                .imageOverlay { episode in
                    if let progress = episode.progress {
                        LandscapePosterProgressBar(
                            title: progress,
                            progress: (episode.userData?.playedPercentage ?? 0) / 100
                        )
                    } else if episode.userData?.played ?? false {
                        ZStack(alignment: .bottomTrailing) {
                            Color.clear

                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30, alignment: .bottomTrailing)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                }
                .content { episode in
                    Button {
                        itemRouter.route(to: \.item, episode)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(episode.episodeLocator ?? L10n.unknown)
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            Text(episode.displayName)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.bottom, 1)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            ZStack(alignment: .topLeading) {
                                Color.clear
                                    .frame(height: staticOverviewHeight)

                                if episode.unaired {
                                    Text(episode.airDateLabel ?? L10n.noOverviewAvailable)
                                } else {
                                    Text(episode.overview ?? L10n.noOverviewAvailable)
                                }
                            }
                            .font(.caption.weight(.light))
                            .foregroundColor(.secondary)
                            .lineLimit(4)
                            .multilineTextAlignment(.leading)

                            L10n.seeMore.text
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(.jellyfinPurple)
                        }
                    }
                }
                .onSelect { item in
                    mainRouter.route(to: \.videoPlayer, .init(item: item))
                }

                // MARK: Genres

                if let genres = viewModel.item.genreItems, !genres.isEmpty {
                    ItemView.GenresHStack(genres: genres)

                    Divider()
                }

                // MARK: Studios

                if let studios = viewModel.item.studios, !studios.isEmpty {
                    ItemView.StudiosHStack(studios: studios)

                    Divider()
                }

                // MARK: Cast and Crew

                if let castAndCrew = viewModel.item.people,
                   !castAndCrew.isEmpty
                {
                    ItemView.CastAndCrewHStack(people: castAndCrew)

                    Divider()
                }

                // MARK: Similar

                if !viewModel.similarItems.isEmpty {
                    ItemView.SimilarItemsHStack(items: viewModel.similarItems)

                    Divider()
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
