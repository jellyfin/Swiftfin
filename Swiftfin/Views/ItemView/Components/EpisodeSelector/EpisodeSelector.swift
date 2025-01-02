//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Defaults
import JellyfinAPI
import OrderedCollections
import SwiftUI

struct SeriesEpisodeSelector: View {

    @ObservedObject
    var viewModel: SeriesItemViewModel

    @State
    private var didSelectPlayButtonSeason = false
    @State
    private var selection: SeasonItemViewModel.ID?

    private var selectionViewModel: SeasonItemViewModel? {
        viewModel.seasons.first(where: { $0.id == selection })
    }

    @ViewBuilder
    private var seasonSelectorMenu: some View {
        Menu {
            ForEach(viewModel.seasons, id: \.season.id) { seasonViewModel in
                Button {
                    selection = seasonViewModel.id
                } label: {
                    if seasonViewModel.id == selection {
                        Label(seasonViewModel.season.displayTitle, systemImage: "checkmark")
                    } else {
                        Text(seasonViewModel.season.displayTitle)
                    }
                }
            }
        } label: {
            Label(
                selectionViewModel?.season.displayTitle ?? .emptyDash,
                systemImage: "chevron.down"
            )
            .labelStyle(.episodeSelector)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {

            seasonSelectorMenu
                .edgePadding([.bottom, .horizontal])

            Group {
                if let selectionViewModel {
                    EpisodeHStack(viewModel: selectionViewModel, playButtonItem: viewModel.playButtonItem)
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
        .onChange(of: selection) { _ in
            guard let selectionViewModel else { return }

            if selectionViewModel.state == .initial {
                selectionViewModel.send(.refresh)
            }
        }
    }
}
