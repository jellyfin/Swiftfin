//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct SeriesEpisodeSelector: View {

    @ObservedObject
    var viewModel: SeriesItemViewModel

    @State
    private var didSelectPlayButtonSeason = false
    @State
    private var selection: PagingSeasonViewModel.ID?

    private var selectionViewModel: PagingSeasonViewModel? {
        viewModel.seasons.first(where: { $0.id == selection }) ?? viewModel.seasons.first
    }

    @ViewBuilder
    private var seasonSelectorMenu: some View {
        if let selectionViewModel {
            if viewModel.seasons.count > 1 {
                Menu {
                    Picker(L10n.seasons, selection: $selection) {
                        ForEach(viewModel.seasons) { season in
                            Text(season.library.displayTitle)
                                .tag(season.id as PagingSeasonViewModel.ID?)
                        }
                    }
                } label: {
                    Label(
                        selectionViewModel.library.displayTitle,
                        systemImage: "chevron.down"
                    )
                    .labelStyle(.episodeSelector)
                }
            } else {
                Text(selectionViewModel.library.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            seasonSelectorMenu
                .edgePadding(.horizontal)

            Group {
                if let selectionViewModel {
                    EpisodeHStack(
                        viewModel: selectionViewModel,
                        playButtonItem: viewModel.playButtonItem
                    )
                } else {
                    LoadingHStack()
                }
            }
            .transition(.opacity.animation(.linear(duration: 0.1)))
        }
        .onReceive(viewModel.playButtonItem.publisher) { newValue in

            guard !didSelectPlayButtonSeason else { return }
            didSelectPlayButtonSeason = true

            if let playButtonSeason = viewModel.seasons.first(where: { $0.id == newValue.seasonID }) {
                selection = playButtonSeason.id
            } else {
                selection = viewModel.seasons.first?.id
            }
        }
        .backport
        .onChange(of: selection) { _, _ in
            guard let selectionViewModel else { return }

            if selectionViewModel.state == .initial {
                selectionViewModel.refresh()
            }
        }
    }
}
