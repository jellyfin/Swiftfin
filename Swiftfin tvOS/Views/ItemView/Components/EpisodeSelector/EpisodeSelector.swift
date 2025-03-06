//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SeriesEpisodeSelector: View {

    // MARK: - Observed & Environment Objects

    @ObservedObject
    var viewModel: SeriesItemViewModel

    @EnvironmentObject
    private var parentFocusGuide: FocusGuide

    // MARK: - State Variables

    @State
    private var didScrollToPlayButtonSeason = false
    @State
    private var selection: SeasonItemViewModel.ID?

    // MARK: - Calculated Variables

    private var selectionViewModel: SeasonItemViewModel? {
        viewModel.seasons.first(where: { $0.id == selection })
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            SeasonHStack(viewModel: viewModel, selection: $selection)
                .environmentObject(parentFocusGuide)

            if let selectionViewModel {
                EpisodeHStack(viewModel: selectionViewModel, playButtonItem: viewModel.playButtonItem)
                    .environmentObject(parentFocusGuide)
            }
        }
        .onReceive(viewModel.playButtonItem.publisher) { newValue in
            guard !didScrollToPlayButtonSeason else { return }

            didScrollToPlayButtonSeason = true

            if let playButtonSeason = viewModel.seasons.first(where: { $0.id == newValue.seasonID }) {
                selection = playButtonSeason.id
            } else {
                selection = viewModel.seasons.first?.id
            }
        }
        .onChange(of: selection) { _, newValue in
            guard let selectionViewModel = viewModel.seasons.first(where: { $0.id == newValue }) else { return }

            if selectionViewModel.state == .initial {
                selectionViewModel.send(.refresh)
            }
        }
        .onFirstAppear {
            if selection == nil {
                selection = viewModel.seasons.first?.id
            }
        }
    }
}
