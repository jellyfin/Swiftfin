//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SeriesEpisodeSelector {

    struct SeasonsHStack: View {

        // MARK: - Environment & Observed Objects

        @EnvironmentObject
        private var focusGuide: FocusGuide

        @ObservedObject
        var viewModel: SeriesItemViewModel

        // MARK: - Selection Binding

        @Binding
        var selection: SeasonItemViewModel.ID?

        // MARK: - Focus Variables

        @FocusState
        private var focusedSeason: SeasonItemViewModel.ID?

        @State
        private var didScrollToPlayButtonSeason = false

        // MARK: - Body

        var body: some View {
            ScrollViewReader { proxy in
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
                    tag: "belowHeader",
                    onContentFocus: { focusedSeason = selection },
                    top: "header",
                    bottom: "episodes"
                )
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
                .onFirstAppear {
                    guard !didScrollToPlayButtonSeason else { return }
                    didScrollToPlayButtonSeason = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        guard let selection else { return }

                        proxy.scrollTo(selection)
                    }
                }
            }
            .scrollClipDisabled()
        }

        // MARK: - Season Button

        @ViewBuilder
        private func seasonButton(season: SeasonItemViewModel) -> some View {
            Button {
                selection = season.id
            } label: {
                Marquee(season.season.displayTitle, animateWhenFocused: true)
                    .frame(maxWidth: 300)
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
