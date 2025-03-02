//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import JellyfinAPI
import SwiftUI

extension EpisodeItemView {

    struct ContentView: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: EpisodeItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {

                VStack(alignment: .center) {
                    ImageView(viewModel.item.imageSource(.primary, maxWidth: 600))
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

                    ShelfView(viewModel: viewModel)
                }

                // MARK: Overview

                ItemView.OverviewView(item: viewModel.item)
                    .overviewLineLimit(4)
                    .padding(.horizontal)

                RowDivider()

                // MARK: Genres

                if let genres = viewModel.item.itemGenres, genres.isNotEmpty {
                    ItemView.GenresHStack(genres: genres)

                    RowDivider()
                }

                // MARK: Studios

                if let studios = viewModel.item.studios, studios.isNotEmpty {
                    ItemView.StudiosHStack(studios: studios)

                    RowDivider()
                }

                // MARK: Cast and Crew

                if let castAndCrew = viewModel.item.people,
                   castAndCrew.isNotEmpty
                {
                    ItemView.CastAndCrewHStack(people: castAndCrew)

                    RowDivider()
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}

extension EpisodeItemView.ContentView {

    struct ShelfView: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: EpisodeItemViewModel

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

                ItemView.AttributesHStack(viewModel: viewModel)

                ItemView.PlayButton(viewModel: viewModel)
                    .frame(maxWidth: 300)
                    .frame(height: 50)

                ItemView.ActionButtonHStack(viewModel: viewModel)
                    .font(.title)
                    .frame(maxWidth: 300)
                    .foregroundStyle(.primary)
            }
        }
    }
}
