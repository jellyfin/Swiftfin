//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import SwiftUI

struct SeriesEpisodeSelector: View {

    // MARK: - Observed & Environment Objects

    @ObservedObject
    var viewModel: SeriesItemViewModel

    @EnvironmentObject
    private var parentFocusGuide: FocusGuide

    // MARK: - State Variables

    @State
    private var didSelectPlayButtonSeason = false
    @State
    private var selection: SeasonItemViewModel.ID?

    // MARK: - Calculated Variables

    private var selectionViewModel: SeasonItemViewModel? {
        viewModel.seasons.first(where: { $0.id == selection })
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            SeasonsHStack(viewModel: viewModel, selection: $selection)
                .environmentObject(parentFocusGuide)

            if let selectionViewModel {
                EpisodeHStack(viewModel: selectionViewModel, playButtonItem: viewModel.playButtonItem)
                    .environmentObject(parentFocusGuide)
            }
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
        .onChange(of: selection) { _, _ in
            guard let selectionViewModel else { return }

            if selectionViewModel.state == .initial {
                selectionViewModel.send(.refresh)
            }
        }
    }
}
