//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension SeriesEpisodeContentGroup {

    struct SeasonSelector: PlatformView {

        @Binding
        var selection: PagingLibraryViewModel<EpisodeLibrary>.ID?

        @FocusState
        private var focusedSeason: PagingLibraryViewModel<EpisodeLibrary>.ID?

        @Router
        private var router

        let seasons: [PagingLibraryViewModel<EpisodeLibrary>]
        let preferredSelection: PagingLibraryViewModel<EpisodeLibrary>.ID?

        private var selectedSeason: PagingLibraryViewModel<EpisodeLibrary>? {
            seasons.first { $0.id == selection }
        }

        private func openEpisodes(
            for season: PagingLibraryViewModel<EpisodeLibrary>
        ) {
            router.route(to: .library(library: season.library))
        }

        @ViewBuilder
        private func singleSeasonButton(
            _ season: PagingLibraryViewModel<EpisodeLibrary>
        ) -> some View {
            Button {
                openEpisodes(for: season)
            } label: {
                HStack(spacing: 3) {
                    Text(season.library.parent.displayTitle)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Image(systemName: "chevron.forward")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary, .secondary)
            .edgePadding(.horizontal)
            .accessibilityAction(named: Text(L10n.openLibrary)) {
                openEpisodes(for: season)
            }
        }

        var tvOSView: some View {
            ScrollView(.horizontal) {
                SelectionTrack(
                    seasons,
                    selection: selection,
                    focus: $focusedSeason
                ) { season in
                    openEpisodes(for: season)
                }
                .controlSize(.large)
                .edgePadding(.horizontal)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .focusSection()
            .defaultFocus(
                $focusedSeason,
                preferredSelection,
                priority: .userInitiated
            )
            .task(id: focusedSeason) {
                await selectSeasonAfterFocusDebounce(focusedSeason)
            }
        }

        private func selectSeasonAfterFocusDebounce(
            _ seasonID: PagingLibraryViewModel<EpisodeLibrary>.ID?
        ) async {
            guard let seasonID, seasonID != selection else { return }

            do {
                try await Task.sleep(for: .milliseconds(350))
            } catch {
                return
            }

            guard seasonID == focusedSeason,
                  seasonID != selection,
                  seasons.contains(where: { $0.id == seasonID })
            else { return }

            selection = seasonID
        }

        var iOSView: some View {
            if seasons.count == 1, let season = seasons.first {
                singleSeasonButton(season)
            } else {
                Menu(
                    selectedSeason?.library.parent.displayTitle ?? L10n.episodes,
                    systemImage: "chevron.down"
                ) {
                    Button(L10n.allEpisodes, systemImage: "list.bullet") {
                        if let selectedSeason {
                            openEpisodes(for: selectedSeason)
                        }
                    }
                    .disabled(selectedSeason == nil)

                    Divider()

                    Picker(L10n.seasons, selection: $selection) {
                        ForEach(seasons) { season in
                            Text(season.library.parent.displayTitle)
                                .tag(season.id)
                        }
                    }
                }
                .labelStyle(.trailingIcon)
                .buttonStyle(.capsule)
                .edgePadding(.horizontal)
            }
        }
    }
}
