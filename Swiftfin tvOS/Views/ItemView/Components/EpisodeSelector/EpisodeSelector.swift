//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import SwiftUI

struct SeriesEpisodeSelector: View {

    @ObservedObject
    var viewModel: _ItemViewModel

    @EnvironmentObject
    private var parentFocusGuide: FocusGuide

    @State
    private var didSelectPlayButtonSeason = false
    @State
    private var selection: PagingSeasonViewModel.ID?

    @StateObject
    private var seasonsViewModel: PagingLibraryViewModel<SeasonViewModelLibrary>

    private var selectionViewModel: PagingSeasonViewModel? {
        guard let id = selection else { return nil }
        return seasonsViewModel.elements[id: id]
    }

    init(viewModel: _ItemViewModel) {
        self.viewModel = viewModel
        self._seasonsViewModel = .init(wrappedValue: .init(library: .init(series: viewModel.item)))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            SeasonsHStack(
                viewModel: seasonsViewModel,
                selection: $selection
            )

            if let selectionViewModel {
                EpisodeHStack(
                    viewModel: selectionViewModel,
                    playButtonItem: viewModel.playButtonItem
                )
            }
        }
        .environmentObject(parentFocusGuide)
        .onReceive(viewModel.playButtonItem.publisher) { newValue in

            guard selection == nil else { return }
            guard let playButtonSeasonID = newValue.seasonID else { return }

            if let playButtonSeason = seasonsViewModel.elements[id: playButtonSeasonID] {
                selection = playButtonSeason.id
            } else {
                selection = seasonsViewModel.elements.first?.id
            }
        }
        .onFirstAppear {
            seasonsViewModel.refresh()
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
