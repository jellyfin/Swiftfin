//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SeriesEpisodeSelector {

    struct SeasonHStack: View {

        @EnvironmentObject
        private var focusGuide: FocusGuide

        @FocusState
        private var focusedSeason: SeasonItemViewModel.ID?

        @ObservedObject
        var viewModel: SeriesItemViewModel

        @Binding
        var selection: SeasonItemViewModel.ID?

        // MARK: - Body

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: EdgeInsets.edgePadding / 2) {
                    ForEach(viewModel.seasons) { season in
                        seasonButton(season: season)
                            .id(season.id)
                    }
                }
                .padding(.horizontal, EdgeInsets.edgePadding)
            }
            .padding(.bottom, 45)
            .focusSection()
            .focusGuide(
                focusGuide,
                tag: "seasons",
                onContentFocus: { focusedSeason = selection },
                top: "top",
                bottom: "episodes"
            )
            .onChange(of: focusedSeason) { _, newValue in
                if let newValue = newValue {
                    selection = newValue
                }
            }
        }

        // MARK: - Season Button

        @ViewBuilder
        private func seasonButton(season: SeasonItemViewModel) -> some View {
            Button {
                selection = season.id
            } label: {
                Text(season.season.displayTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .if(selection == season.id) { text in
                        text
                            .background(.white)
                            .foregroundColor(.black)
                    }
            }
            .focused($focusedSeason, equals: season.id)
            .buttonStyle(.card)
            .padding(.horizontal, 4)
            .padding(.vertical)
        }
    }
}
