//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct SeriesEpisodesView<RowManager: EpisodesRowManager>: View {

    @EnvironmentObject
    private var itemRouter: ItemCoordinator.Router
    @ObservedObject
    var viewModel: RowManager

    @ViewBuilder
    private var headerView: some View {
        HStack {
            Menu {
                ForEach(viewModel.sortedSeasons) { season in
                    Button {
                        viewModel.select(season: season)
                    } label: {
                        if season.id == viewModel.selectedSeason?.id {
                            Label(season.name ?? L10n.unknown, systemImage: "checkmark")
                        } else {
                            Text(season.name ?? L10n.unknown)
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Group {
                        Text(viewModel.selectedSeason?.name ?? L10n.unknown)
                            .fixedSize()
                        Image(systemName: "chevron.down")
                    }
                    .font(.title3.weight(.semibold))
                }
            }

            Spacer()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            headerView
                .padding(.horizontal)
                .if(UIDevice.isIPad) { view in
                    view.padding(.horizontal)
                }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 15) {
                    if viewModel.isLoading {
                        ForEach(0 ..< 5) { _ in
                            EpisodeCard(episode: .placeHolder)
                                .redacted(reason: .placeholder)
                        }
                    } else if let selectedSeason = viewModel.selectedSeason {
                        if let seasonEpisodes = viewModel.seasonsEpisodes[selectedSeason] {
                            if seasonEpisodes.isEmpty {
                                EpisodeCard(episode: .noResults)
                            } else {
                                ForEach(seasonEpisodes) { episode in
                                    EpisodeCard(episode: episode)
                                        .id(episode.id)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .if(UIDevice.isIPad) { view in
                    view.padding(.horizontal)
                }
            }
        }
    }
}
