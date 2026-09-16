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

        let seasons: [PagingLibraryViewModel<EpisodeLibrary>]

        @Binding
        var selection: PagingLibraryViewModel<EpisodeLibrary>.ID?

        let preferredSelection: PagingLibraryViewModel<EpisodeLibrary>.ID?

        @FocusState
        private var focusedSeason: PagingLibraryViewModel<EpisodeLibrary>.ID?
        @FocusState
        private var isPickerFocused: Bool

        private var selectedSeason: PagingLibraryViewModel<EpisodeLibrary>? {
            seasons.first { $0.id == selection }
        }

        @ViewBuilder
        private func title(_ value: String) -> some View {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .edgePadding(.horizontal)
        }

        var tvOSView: some View {
            if seasons.isEmpty {
                title(L10n.episodes)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 20) {
                        ForEach(seasons) { season in
                            let isSelected = selection == season.id

                            Button(season.library.parent.displayTitle) {
                                selection = season.id
                            }
                            .buttonStyle(
                                SeasonButtonStyle(
                                    isFocused: focusedSeason == season.id,
                                    isPickerFocused: isPickerFocused
                                )
                            )
                            .isSelected(isSelected)
                            .focused($focusedSeason, equals: season.id)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                    .edgePadding(.horizontal)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                .focusSection()
                .focused($isPickerFocused)
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

            @Environment(\.isSelected)
            private var isSelected

            /// Focus comes from the picker's own `FocusState` rather than `\.isFocused`,
            /// so that it cannot depend on the environment reaching a `ButtonStyle` body.
            let isFocused: Bool
            let isPickerFocused: Bool

            /// Whether the button draws a filled capsule: the season being moved over
            /// while the row has focus, or the chosen season while focus is elsewhere.
            private var isHighlighted: Bool {
                isFocused || (!isPickerFocused && isSelected)
            }

            /// The chosen season states its case more quietly while focus is elsewhere,
            /// so the fill reads as "where you are" once the row is entered.
            private var inactiveSelectedOpacity: Double {
                isSelected && !isFocused ? 0.72 : 1
            }

            private var glass: BackportGlass {
                isHighlighted ? .regular.selection(
                    tint: .white,
                    foregroundColor: .black
                ) : .identity
            }

            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .font(.callout)
                    .fontWeight(.semibold)
                    .padding(CapsuleLabelStyle.defaultInsets)
                    .backport
                    .glassEffect(glass, in: .capsule)
                    // A filled capsule on its own cannot say whether the row has focus:
                    // entering it only moves the fill from the chosen season onto the one
                    // under focus, and entering on the chosen season moves nothing at all.
                    .opacity(inactiveSelectedOpacity)
                    .scaleEffect(isFocused ? 1.1 : 1)
                    .shadow(
                        color: .black.opacity(isFocused ? 0.5 : 0),
                        radius: isFocused ? 10 : 0
                    )
                    .animation(.easeInOut(duration: 0.15), value: isFocused)
                    .animation(.easeInOut(duration: 0.15), value: isHighlighted)
            }
        }

        var iOSView: some View {
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
    }
}
