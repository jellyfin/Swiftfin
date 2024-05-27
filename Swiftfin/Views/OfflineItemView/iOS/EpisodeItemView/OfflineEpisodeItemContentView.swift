//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import JellyfinAPI
import SwiftUI

extension OfflineEpisodeItemView {
    struct ContentView: View {

        @EnvironmentObject
        private var router: OfflineItemCoordinator.Router

        @ObservedObject
        var viewModel: OfflineEpisodeItemViewModel

        @ObservedObject
        var offlineViewModel: OfflineViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {

                VStack(alignment: .center) {
                    // TODO: handle properly
                    ImageView(viewModel.download!.landscapeImageSources(maxWidth: 600))
                        .placeholder { source in
                            if let blurHash = source.blurHash {
                                BlurHashView(blurHash: blurHash, size: .Square(length: 8))
                            } else {
                                Color.secondarySystemFill
                                    .opacity(0.75)
                            }
                        }
                        .failure {
                            SystemImageContentView(systemName: viewModel.item.systemImage)
                        }
                        .frame(maxHeight: 300)
                        .posterStyle(.landscape)
                        .posterShadow()
                        .padding(.horizontal)

                    ShelfView(viewModel: viewModel, offlineViewModel: offlineViewModel)
                }

                // MARK: Overview

                OfflineItemView.OverviewView(item: viewModel.item)
                    .overviewLineLimit(4)
                    .padding(.horizontal)

                RowDivider()

                // MARK: Genres

                if let genres = viewModel.item.itemGenres, genres.isNotEmpty {
                    OfflineItemView.GenresHStack(genres: genres)

                    RowDivider()
                }

                // MARK: Studios

                if let studios = viewModel.item.studios, studios.isNotEmpty {
                    OfflineItemView.StudiosHStack(studios: studios)

                    RowDivider()
                }

                // MARK: Series

                // TODO: have different way to get to series item
                //       - about view poster?
                if let seriesItem = viewModel.seriesItem {
                    PosterHStack(
                        title: L10n.series,
                        type: .portrait,
                        items: [seriesItem]
                    )
                    .onSelect { item in
                        router.route(to: \.item, item)
                    }
                }

                OfflineItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}

extension OfflineEpisodeItemView.ContentView {

    struct ShelfView: View {

        @EnvironmentObject
        private var router: OfflineItemCoordinator.Router

        @ObservedObject
        var viewModel: OfflineEpisodeItemViewModel
        @ObservedObject
        var offlineViewModel: OfflineViewModel

        var body: some View {
            VStack(alignment: .center, spacing: 10) {
                Text(viewModel.item.seriesName ?? .emptyDash)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)

                Text(viewModel.item.displayTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)

                DotHStack {
                    if let seasonEpisodeLabel = viewModel.item.seasonEpisodeLabel {
                        Text(seasonEpisodeLabel)
                    }

                    if let productionYear = viewModel.item.premiereDateYear {
                        Text(productionYear)
                    }

                    if let runtime = viewModel.item.runTimeLabel {
                        Text(runtime)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

                OfflineItemView.AttributesHStack(viewModel: viewModel)

                OfflineItemView.PlayButton(offlineViewModel: offlineViewModel, viewModel: viewModel)
                    .frame(maxWidth: 300)
                    .frame(height: 50)

                OfflineItemView.ActionButtonHStack(viewModel: viewModel)
                    .font(.title)
                    .frame(maxWidth: 300)
                    .foregroundStyle(.primary)
            }
        }
    }
}
