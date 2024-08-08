//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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
    private var selection: SeasonItemViewModel?

    @ViewBuilder
    private var seasonSelectorMenu: some View {
        Menu {
            ForEach(viewModel.seasons, id: \.season.id) { seasonViewModel in
                Button {
                    selection = seasonViewModel
                } label: {
                    if seasonViewModel == selection {
                        Label(seasonViewModel.season.displayTitle, systemImage: "checkmark")
                    } else {
                        Text(seasonViewModel.season.displayTitle)
                    }
                }
            }
        } label: {
            Label(
                selection?.season.displayTitle ?? .emptyDash,
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
                if let selection {
                    EpisodeHStack(viewModel: selection, playButtonItem: viewModel.playButtonItem)
                } else {
                    LoadingHStack()
                }
            }
            .transition(.opacity.animation(.linear(duration: 0.1)))
        }
        .onReceive(viewModel.playButtonItem.publisher) { newValue in

            guard !didSelectPlayButtonSeason else { return }
            didSelectPlayButtonSeason = true

            if let season = viewModel.seasons.first(where: { $0.season.id == newValue.seasonID }) {
                selection = season
            } else {
                selection = viewModel.seasons.first
            }
        }
        .onChange(of: selection) { newValue in
            guard let newValue else { return }

            if newValue.state == .initial {
                newValue.send(.refresh)
            }
        }
    }
}
