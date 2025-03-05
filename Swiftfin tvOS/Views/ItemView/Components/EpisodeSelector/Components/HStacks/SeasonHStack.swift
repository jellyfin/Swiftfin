//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import SwiftUI

extension SeriesEpisodeSelector {

    // MARK: SeasonsHStack

    struct SeasonsHStack: View {

        @EnvironmentObject
        private var focusGuide: FocusGuide

        @FocusState
        private var focusedSeason: SeasonItemViewModel.ID?

        @ObservedObject
        var viewModel: SeriesItemViewModel

        @Binding
        var selection: SeasonItemViewModel.ID?

        @State
        private var didScrollToPlayButtonSeason = false

        @StateObject
        private var proxy = CollectionHStackProxy()

        // MARK: - Extracted helper methods

        private func scrollToSelectedSeason() {
            if let selectedID = selection,
               let index = viewModel.seasons.firstIndex(where: { $0.id == selectedID }),
               index > 0
            {
                proxy.scrollTo(index: index, animated: false)
            }
        }

        private func onFocusSeasonChanged(_ newValue: SeasonItemViewModel.ID?) {
            guard let newValue = newValue else { return }
            selection = newValue
        }

        // MARK: - Body

        var body: some View {
            CollectionHStack(
                uniqueElements: viewModel.seasons,
                id: \.id,
                variadicWidths: true
            ) { season in
                seasonButton(season: season)
                    .id(season.id)
            }
            .scrollBehavior(.continuous)
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
                onContentFocus: { focusedSeason = selection },
                top: "top",
                bottom: "episodes"
            )
            .onFirstAppear {
                guard !didScrollToPlayButtonSeason else { return }
                didScrollToPlayButtonSeason = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToSelectedSeason()
                }
            }
        }

        // MARK: - Season Button

        private func seasonButton(season: SeasonItemViewModel) -> some View {
            Button {} label: {
                Text(season.season.displayTitle)
                    .fixedSize()
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(selection == season.id ? Color.white : Color.clear)
                    .foregroundColor(selection == season.id ? Color.black : Color.white)
            }
            .buttonStyle(.card)
            .focused($focusedSeason, equals: season.id)
        }
    }
}
