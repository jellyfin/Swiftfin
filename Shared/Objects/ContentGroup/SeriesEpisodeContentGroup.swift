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

    let id: String
    let playButtonItem: BaseItemDto?
    let series: BaseItemDto
    let viewModel: PagingLibraryViewModel<SeasonViewModelLibrary>

    var displayTitle: String {
        L10n.episodes
    }

    var _shouldBeResolved: Bool {
        viewModel.elements.isNotEmpty
    }

    init(
        series: BaseItemDto,
        playButtonItem: BaseItemDto? = nil
    ) {
        self.id = "\(series.id ?? "series")-episode-selector"
        self.playButtonItem = playButtonItem
        self.series = series
        self.viewModel = .init(library: SeasonViewModelLibrary(series: series), pageSize: 100)
    }

    func body(with viewModel: PagingLibraryViewModel<SeasonViewModelLibrary>) -> Body {
        Body(
            viewModel: viewModel,
            playButtonItem: playButtonItem
        )
    }

    struct Body: View {

        @ObservedObject
        var viewModel: PagingLibraryViewModel<SeasonViewModelLibrary>

        let playButtonItem: BaseItemDto?

        @State
        private var selection: PagingLibraryViewModel<EpisodeLibrary>.ID?

        private var selectedSeasonViewModel: PagingLibraryViewModel<EpisodeLibrary>? {
            viewModel.elements.first { $0.id == selection }
        }

        private var seasonSelectorView: some View {
            SeasonSelector(
                seasons: Array(viewModel.elements),
                selection: $selection,
                preferredSelection: selection ?? preferredSeasonSelection()
            )
        }

        private func preferredSeasonSelection() -> PagingLibraryViewModel<EpisodeLibrary>.ID? {
            if let playButtonSeasonID = playButtonItem?.seasonID,
               viewModel.elements.contains(where: { $0.id == playButtonSeasonID })
            {
                return playButtonSeasonID
            }

            return viewModel.elements.first?.id
        }

        private func selectPreferredSeasonIfNeeded() {
            if selection == nil || !viewModel.elements.contains(where: { $0.id == selection }) {
                selection = preferredSeasonSelection()
            }
        }

        private func refreshSelectedSeasonIfNeeded() {
            guard let selectedSeasonViewModel, selectedSeasonViewModel.state == .initial else { return }
            selectedSeasonViewModel.refresh()
        }

        @ViewBuilder
        var body: some View {
            Group {
                if let selectedSeasonViewModel {
                    SeasonEpisodesView(
                        seasonViewModel: selectedSeasonViewModel,
                        playButtonItem: playButtonItem
                    ) {
                        seasonSelectorView
                    }
                } else {
                    LoadingEpisodesView {
                        seasonSelectorView
                    }
                }
            }
            .onFirstAppear {
                selectPreferredSeasonIfNeeded()
                refreshSelectedSeasonIfNeeded()
            }
            .backport
            .onChange(of: viewModel.elements.count) {
                selectPreferredSeasonIfNeeded()
            }
            .backport
            .onChange(of: selection) {
                refreshSelectedSeasonIfNeeded()
            }
        }
    }
}
