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

    // MARK: - Observed & Environment Objects

    @ObservedObject
    var viewModel: SeriesItemViewModel

    @EnvironmentObject
    private var parentFocusGuide: FocusGuide

    // MARK: - State Variables

    @State
    private var didSelectPlayButtonSeason = false
    @State
    private var selection: SeasonItemViewModel.ID?

    // MARK: - Calculated Variables

    private var selectionViewModel: SeasonItemViewModel? {
        viewModel.seasons.first(where: { $0.id == selection })
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            SeasonsHStack(viewModel: viewModel, selection: $selection)
                .environmentObject(parentFocusGuide)

            if let selectionViewModel {
                EpisodeHStack(viewModel: selectionViewModel, playButtonItem: viewModel.playButtonItem)
                    .environmentObject(parentFocusGuide)
            }
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
        .onChange(of: selection) { _, newValue in
            guard let selectionViewModel = viewModel.seasons.first(where: { $0.id == newValue }) else { return }

            if selectionViewModel.state == .initial {
                selectionViewModel.send(.refresh)
            }
        }
    }
}

extension SeriesEpisodeSelector {

    // MARK: SeasonsHStack

    struct SeasonsHStack: View {

        @EnvironmentObject
        private var focusGuide: FocusGuide

        @FocusState
        private var focusedSeason: SeasonItemViewModel.ID?

        @ObservedObject
        var viewModel: SeriesItemViewModel

        var selection: Binding<SeasonItemViewModel.ID?>

        @State
        private var didScrollToPlayButtonItem = false

        @StateObject
        private var proxy = CollectionHStackProxy()

        // MARK: - Extracted helper methods

        private func scrollToSelectedSeason() {
            let selectedID = selection.wrappedValue
            let seasons = viewModel.seasons

            if let selectedID = selectedID,
               let index = seasons.firstIndex(where: { $0.id == selectedID })
            {
                proxy.scrollTo(index: index, animated: false)
            } else if !seasons.isEmpty {
                proxy.scrollTo(index: 0, animated: false)
            }
        }

        private func onFocusSeasonChanged(_ newValue: SeasonItemViewModel.ID?) {
            guard let newValue = newValue else { return }
            selection.wrappedValue = newValue
        }

        // MARK: - Body

        var body: some View {
            CollectionHStack(
                uniqueElements: viewModel.seasons,
                id: \.id,
                variadicWidths: true
            ) { season in
                seasonButton(viewModel: season)
                    .id(season.id)
            }
            .scrollBehavior(.continuousLeadingEdge)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding)
            .proxy(proxy)
            .frame(height: 70)
            .padding(.top)
            .padding(.bottom, 45)
            .onChange(of: focusedSeason) { _, newValue in
                onFocusSeasonChanged(newValue)
            }
            .focusGuide(
                focusGuide,
                tag: "seasons",
                onContentFocus: { focusedSeason = selection.wrappedValue },
                top: "top",
                bottom: "episodes"
            )
            .onFirstAppear {
                guard !didScrollToPlayButtonItem else { return }
                didScrollToPlayButtonItem = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToSelectedSeason()
                }
            }
        }

        // MARK: - Season Button

        private func seasonButton(viewModel seasonViewModel: SeasonItemViewModel) -> some View {
            // Create the base button content
            let text = Text(seasonViewModel.season.displayTitle)
                .fixedSize()
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)

            // Apply conditional styling
            let isSelected = selection.wrappedValue == seasonViewModel.id
            let styledText = text
                .background(isSelected ? Color.white : Color.clear)
                .foregroundColor(isSelected ? Color.black : Color.white)

            // Create the button
            return Button {
                // Empty action
            } label: {
                styledText
            }
            .buttonStyle(.card)
            .focused($focusedSeason, equals: seasonViewModel.id)
        }
    }
}
