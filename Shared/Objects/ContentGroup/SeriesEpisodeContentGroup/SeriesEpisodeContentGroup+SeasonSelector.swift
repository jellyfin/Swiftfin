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

    struct SeasonSelector: View {

        let seasons: [PagingLibraryViewModel<EpisodeLibrary>]

        @Binding
        var selection: PagingLibraryViewModel<EpisodeLibrary>.ID?

        let preferredSelection: PagingLibraryViewModel<EpisodeLibrary>.ID?

        #if os(tvOS)
        @FocusState
        private var focusedSeason: PagingLibraryViewModel<EpisodeLibrary>.ID?
        @FocusState
        private var isPickerFocused: Bool
        #endif

        private var selectedSeason: PagingLibraryViewModel<EpisodeLibrary>? {
            seasons.first { $0.id == selection }
        }

        #if os(tvOS)
        @ViewBuilder
        private var tvOSBody: some View {
            if seasons.isEmpty {
                title(L10n.episodes)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 20) {
                        ForEach(seasons) { season in
                            let isSelected = selection == season.id

                            Button {
                                selection = season.id
                            } label: {
                                EmptyLabel(season.library.parent.displayTitle)
                            }
                            .buttonStyle(SeasonButtonStyle(isPickerFocused: isPickerFocused))
                            .isSelected(isSelected)
                            .focused($focusedSeason, equals: season.id)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                    .edgePadding(.horizontal)
                }
                .scrollIndicators(.hidden)
                .backport
                .scrollClipDisabled()
                .focusSection()
                .focused($isPickerFocused)
                .backport
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

        private struct SeasonButtonStyle: ButtonStyle {

            @Environment(\.isFocused)
            private var isFocused
            @Environment(\.isSelected)
            private var isSelected

            let isPickerFocused: Bool

            private var isHighlighted: Bool {
                isFocused || (!isPickerFocused && isSelected)
            }

            @ViewBuilder
            private func label(_ configuration: Configuration) -> some View {
                if isHighlighted {
                    configuration.label
                        .foregroundStyle(.black)
                        .labelStyle(
                            CapsuleLabelStyle(
                                tint: .white
                            )
                        )
                } else {
                    configuration.label
                        .foregroundStyle(.primary)
                        .labelStyle(.titleOnly)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
            }

            func makeBody(configuration: Configuration) -> some View {
                label(configuration)
                    .font(.body)
                    .fontWeight(.semibold)
                    .scaleEffect(isFocused ? 1.06 : 1)
                    .shadow(
                        color: isFocused ? .black.opacity(0.5) : .clear,
                        radius: isFocused ? 10 : 0
                    )
                    .animation(.easeInOut(duration: 0.1), value: isFocused)
                    .animation(.easeInOut(duration: 0.1), value: isHighlighted)
            }
        }
        #else
        @ViewBuilder
        private var iOSBody: some View {
            if seasons.count <= 1 {
                title(selectedSeason?.library.parent.displayTitle ?? L10n.episodes)
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
                .labelStyle(
                    CapsuleLabelStyle(
                        isIconTrailing: true
                    )
                )
                .font(.headline)
                .edgePadding(.horizontal)
            }
        }
        #endif

        private func title(_ value: String) -> some View {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .edgePadding(.horizontal)
        }

        var body: some View {
            #if os(tvOS)
            tvOSBody
            #else
            iOSBody
            #endif
        }
    }
}
