//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct SeriesEpisodeSelector: View {

    @ObservedObject
    var viewModel: SeriesItemViewModel

    @State
    private var didSelectPlayButtonSeason = false
    @State
    private var selection: PagingLibraryViewModel<EpisodeLibrary>.ID?

    private var selectionViewModel: PagingLibraryViewModel<EpisodeLibrary>? {
        viewModel.seasons.first(where: { $0.id == selection })
    }

    @ViewBuilder
    private var seasonSelectorMenu: some View {
        if let seasonDisplayName = selectionViewModel?.library.parent.displayTitle,
           viewModel.seasons.count <= 1
        {
            Text(seasonDisplayName)
                .font(.title2)
                .fontWeight(.semibold)
        } else {
            Menu {
                ForEach(viewModel.seasons, id: \.library.parent.id) { seasonViewModel in
                    Button {
                        selection = seasonViewModel.id
                    } label: {
                        if seasonViewModel.id == selection {
                            Label(seasonViewModel.library.parent.displayTitle, systemImage: "checkmark")
                        } else {
                            Text(seasonViewModel.library.parent.displayTitle)
                        }
                    }
                }
            } label: {
                Label(
                    selectionViewModel?.library.parent.displayTitle ?? .emptyDash,
                    systemImage: "chevron.down"
                )
                .labelStyle(.episodeSelector)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            seasonSelectorMenu
                .edgePadding(.horizontal)

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
                selectionViewModel.refresh()
            }
        }
    }
}
