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

        @Router
        private var router

        let seasons: [PagingLibraryViewModel<EpisodeLibrary>]

        @Binding
        var selection: PagingLibraryViewModel<EpisodeLibrary>.ID?

        let preferredSelection: PagingLibraryViewModel<EpisodeLibrary>.ID?

        @FocusState
        private var focusedSeason: PagingLibraryViewModel<EpisodeLibrary>.ID?

        private var selectedSeason: PagingLibraryViewModel<EpisodeLibrary>? {
            seasons.first { $0.id == selection }
        }

        private func openEpisodeList(
            _ season: PagingLibraryViewModel<EpisodeLibrary>
        ) {
            router.route(to: .library(library: season.library))
        }

        @ViewBuilder
        private func title(_ value: String) -> some View {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .edgePadding(.horizontal)
        }

        private func singleSeasonButton(
            _ season: PagingLibraryViewModel<EpisodeLibrary>
        ) -> some View {
            Button(action: { openEpisodeList(season) }) {
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
            .accessibilityAction(named: Text(L10n.openLibrary)) { openEpisodeList(season) }
        }

        var tvOSView: some View {
            if seasons.isEmpty {
                title(L10n.episodes)
            } else {
                ScrollView(.horizontal) {
                    SelectionTrack(
                        seasons,
                        selection: selection,
                        focus: $focusedSeason
                    ) { season in
                        openEpisodeList(season)
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
        }

        @MainActor
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
            if seasons.isEmpty {
                title(L10n.episodes)
            } else if let season = seasons.first, seasons.count == 1 {
                singleSeasonButton(season)
            } else {
                Menu(
                    selectedSeason?.library.parent.displayTitle ?? L10n.episodes,
                    systemImage: "chevron.down"
                ) {
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
