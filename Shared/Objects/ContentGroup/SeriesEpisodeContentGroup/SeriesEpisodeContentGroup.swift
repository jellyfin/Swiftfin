//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: when used for single seasons, have title as just "Episodes" or
//       have functionality in PosterGroup

struct SeriesEpisodeContentGroup: ContentGroup, Identifiable {

    let id: String
    @OptionalSharedBaseItem
    var playButtonItem: BaseItemDto?
    let viewModel: PagingLibraryViewModel<SeasonViewModelLibrary>

    var _shouldBeResolved: Bool {
        viewModel.elements.isNotEmpty
    }

    init(
        parent: BaseItemDto,
        playButtonItem: BaseItemDto? = nil
    ) {
        self.id = "\(parent.id ?? "parent")-episode-selector"
        self.playButtonItem = playButtonItem
        self.viewModel = .init(library: SeasonViewModelLibrary(parent: parent), pageSize: 100)
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

        @Router
        private var router

        @OptionalSharedBaseItem
        var playButtonItem: BaseItemDto?

        @State
        private var selection: PagingLibraryViewModel<EpisodeLibrary>.ID?

        private var selectedSeasonViewModel: PagingLibraryViewModel<EpisodeLibrary>? {
            viewModel.elements.first { $0.id == selection }
        }

        private var seasonSelector: some View {
            SeasonSelector(
                seasons: Array(viewModel.elements),
                selection: $selection,
                preferredSelection: selection ?? preferredSeasonSelection(),
                openEpisodeList: openEpisodeList
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

        private func openEpisodeList(
            for seasonViewModel: PagingLibraryViewModel<EpisodeLibrary>
        ) {
            router.route(
                to: .library(
                    library: seasonViewModel.library,
                    displayType: .list
                )
            )
        }

        private func openSelectedEpisodeList() {
            guard let selectedSeasonViewModel else { return }

            openEpisodeList(for: selectedSeasonViewModel)
        }

        @ViewBuilder
        private var episodeSectionHeader: some View {
            #if os(iOS)
            HStack {
                seasonSelector

                Spacer()

                Button(
                    L10n.allEpisodes,
                    systemImage: "list.bullet",
                    action: openSelectedEpisodeList
                )
                .buttonStyle(.capsule)
                .padding(.trailing, EdgeInsets.edgePadding)
                .disabled(selectedSeasonViewModel == nil)
            }
            #else
            seasonSelector
            #endif
        }

        @ViewBuilder
        var body: some View {
            Group {
                if let selectedSeasonViewModel {
                    SeasonEpisodesView(
                        seasonViewModel: selectedSeasonViewModel,
                        playButtonItem: playButtonItem
                    ) {
                        episodeSectionHeader
                    }
                } else {
                    LoadingEpisodesView {
                        episodeSectionHeader
                    }
                }
            }
            .onFirstAppear {
                selectPreferredSeasonIfNeeded()
                refreshSelectedSeasonIfNeeded()
            }
            .onChange(of: viewModel.elements.map(ObjectIdentifier.init)) {
                selectPreferredSeasonIfNeeded()
                refreshSelectedSeasonIfNeeded()
            }
            .onChange(of: selection) {
                refreshSelectedSeasonIfNeeded()
            }
        }
    }
}
