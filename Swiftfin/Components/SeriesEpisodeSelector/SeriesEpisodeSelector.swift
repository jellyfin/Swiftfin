//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct SeriesEpisodeContentGroup: _ContentGroup, Identifiable {

    let viewModel: _ItemViewModel
    var id: String { "\(viewModel.item.libraryID)-episodeSelector" }

    func body(with viewModel: _ItemViewModel) -> some View {
        SeriesEpisodeSelector(viewModel: viewModel)
    }
}

struct SeriesEpisodeSelector: View {

    @ObservedObject
    private var viewModel: _ItemViewModel

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

    @ViewBuilder
    private var seasonSelectorMenu: some View {
        if let selectionViewModel {
            if seasonsViewModel.elements.count > 1 {
                Menu {
                    Picker(L10n.seasons, selection: $selection) {
                        ForEach(seasonsViewModel.elements, id: \.id) { season in
                            Text(season.library.parent.displayTitle)
                                .tag(season.id as PagingSeasonViewModel.ID?)
                        }
                    }
                } label: {
                    Label(
                        selectionViewModel.library.parent.displayTitle,
                        systemImage: "chevron.down"
                    )
                    .labelStyle(.episodeSelector)
                }
            } else {
                Text(selectionViewModel.library.parent.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        } else {
            Text(verbatim: .emptyDash)
                .font(.title2)
                .fontWeight(.semibold)
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
                }
//                else {
//                    LoadingHStack()
//                }
            }
            .transition(.opacity.animation(.linear(duration: 0.1)))
        }
        .onReceive(viewModel.playButtonItem.publisher) { newValue in

            guard selection == nil else { return }
            guard let playButtonSeasonID = newValue.seasonID else { return }

            if let playButtonSeason = seasonsViewModel.elements[id: playButtonSeasonID] {
                selection = playButtonSeason.id
            } else {
                selection = seasonsViewModel.elements.first?.id
            }

//            guard !didSelectPlayButtonSeason else { return }
//            didSelectPlayButtonSeason = true
//
//            if let playButtonSeason = viewModel.seasons.first(where: { $0.id == newValue.seasonID }) {
//                selection = playButtonSeason.id
//            } else {
//                selection = viewModel.seasons.first?.id
//            }
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
