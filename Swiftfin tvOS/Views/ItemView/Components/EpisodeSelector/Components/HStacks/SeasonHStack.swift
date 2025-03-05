//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SeriesEpisodeSelector {

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
        private var hasScrolledToSelection = false

        // MARK: - Body

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: EdgeInsets.edgePadding / 2) {
                    ForEach(viewModel.seasons) { seasonViewModel in
                        seasonButton(for: seasonViewModel)
                    }
                }
                .focusGuide(
                    focusGuide,
                    tag: "seasons",
                    onContentFocus: { focusedSeason = selection },
                    top: "top",
                    bottom: "episodes"
                )
                .frame(height: 70)
                .padding(.horizontal, 50)
                .padding(.top)
                .padding(.bottom, 45)
            }
            .focusable(false)
            .mask {
                VStack(spacing: 0) {
                    Color.white
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20)
                }
            }
            .onChange(of: focusedSeason) { _, newValue in
                if let newValue = newValue {
                    selection = newValue
                }
            }
        }

        // MARK: - Season Button

        private func seasonButton(for seasonViewModel: SeasonItemViewModel) -> some View {
            Button {
                selection = seasonViewModel.id
            } label: {
                Text(seasonViewModel.season.displayTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(selection == seasonViewModel.id ? Color.white : Color.clear)
                    .foregroundColor(selection == seasonViewModel.id ? Color.black : Color.white)
            }
            .buttonStyle(.card)
            .focused($focusedSeason, equals: seasonViewModel.id)
            .id(seasonViewModel.id)
        }
    }
}
