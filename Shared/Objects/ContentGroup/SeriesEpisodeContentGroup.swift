//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct SeriesEpisodeContentGroup: ContentGroup, Identifiable {

    let viewModel: ItemViewModel
    var id: String { "\(viewModel.item.libraryID)-episodeSelector" }

    func body(with viewModel: ItemViewModel) -> some View {
        SeriesEpisodeSelector(viewModel: viewModel)
    }
}

// TODO: refactor to not take ItemViewModel

struct SeriesEpisodeSelector: View {

    @ObservedObject
    var viewModel: ItemViewModel

    @State
    private var didSelectPlayButtonSeason = false
    @State
    private var selectionID: PagingSeasonViewModel.ID?

    @StateObject
    private var seasonsViewModel: PagingLibraryViewModel<SeasonViewModelLibrary>

    private var selectionViewModel: PagingSeasonViewModel? {
        guard let id = selectionID else { return nil }
        return seasonsViewModel.elements[id: id]
    }

    init(viewModel: ItemViewModel) {
        self.viewModel = viewModel
        self._seasonsViewModel = .init(wrappedValue: .init(library: .init(series: viewModel.item)))
    }

    @ViewBuilder
    private var seasonSelectorMenu: some View {
        #if os(tvOS)
        SeasonsHStack(
            viewModel: seasonsViewModel,
            selection: $selectionID
        )
        #else
        AlternateLayoutView(alignment: .leading) {
            Text(" ")
                .frame(maxWidth: .infinity)
                .font(.title2)
                .fontWeight(.semibold)
        } content: {
            if let selectionViewModel {
                if seasonsViewModel.elements.count > 1 {
                    Menu(
                        selectionViewModel.library.parent.displayTitle,
                        systemImage: "chevron.down"
                    ) {
                        Picker(L10n.seasons, selection: $selectionID) {
                            ForEach(seasonsViewModel.elements, id: \.id) { season in
                                Text(season.library.parent.displayTitle)
                                    .tag(season.id as PagingSeasonViewModel.ID?)
                            }
                        }
                    }
                    .labelStyle(.episodeSelector)
                } else {
                    Text(selectionViewModel.library.parent.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                }
            } else {
                Text(String.random(count: 8))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .redacted(reason: .placeholder)
            }
        }
        .edgePadding(.horizontal)
        #endif
    }

    var body: some View {
        if seasonsViewModel.state != .content || seasonsViewModel.elements.isNotEmpty {
            ZStack {
                EpisodeHStack(
                    viewModel: .init(library: EpisodeLibrary(season: .init())),
                    playButtonItemID: nil
                ) {
                    seasonSelectorMenu
                }
                .opacity(0)

                if let selectionViewModel {
                    EpisodeHStack(
                        viewModel: selectionViewModel,
                        playButtonItemID: viewModel.playButtonItem?.id
                    ) {
                        seasonSelectorMenu
                    }
                } else {
                    EpisodeHStack(
                        viewModel: .init(library: EpisodeLibrary(season: .init())),
                        playButtonItemID: nil
                    ) {
                        seasonSelectorMenu
                    }
                }
            }
            .transition(.opacity.animation(.linear(duration: 0.2)))
            .withViewContext(.isInParent)
            .onReceive(viewModel.playButtonItem.publisher) { newValue in

                guard selectionID == nil else { return }
                guard let playButtonSeasonID = newValue.seasonID else { return }

                if let playButtonSeason = seasonsViewModel.elements[id: playButtonSeasonID] {
                    selectionID = playButtonSeason.id
                } else {
                    selectionID = seasonsViewModel.elements.first?.id
                }
            }
            .onFirstAppear {
                seasonsViewModel.refresh()
            }
            .backport
            .onChange(of: selectionID) { _, _ in
                guard let selectionViewModel else { return }

                if selectionViewModel.state == .initial {
                    selectionViewModel.refresh()
                }
            }
        }
    }
}
