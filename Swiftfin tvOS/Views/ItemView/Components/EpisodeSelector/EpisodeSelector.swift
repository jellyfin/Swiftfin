//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import SwiftUI

struct SeriesEpisodeSelector: View {

    @ObservedObject
    var viewModel: SeriesItemViewModel

    @EnvironmentObject
    private var parentFocusGuide: FocusGuide

    @State
    private var didSelectPlayButtonSeason = false
    @State
    private var selection: SeasonItemViewModel?

    var body: some View {
        VStack(spacing: 0) {
            SeasonsHStack(viewModel: viewModel, selection: $selection)
                .environmentObject(parentFocusGuide)

            if let selection {
                EpisodeHStack(viewModel: selection, playButtonItem: viewModel.playButtonItem)
                    .environmentObject(parentFocusGuide)
            } else {
                LoadingHStack()
            }
        }
        .onReceive(viewModel.playButtonItem.publisher) { newValue in

            guard !didSelectPlayButtonSeason else { return }
            didSelectPlayButtonSeason = true

            if let season = viewModel.seasons.first(where: { $0.season.id == newValue.seasonID }) {
                selection = season
            } else {
                selection = viewModel.seasons.first
            }
        }
        .onChange(of: selection) { _, newValue in
            guard let newValue else { return }

            if newValue.state == .initial {
                newValue.send(.refresh)
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
        private var focusedSeason: SeasonItemViewModel?

        @ObservedObject
        var viewModel: SeriesItemViewModel

        var selection: Binding<SeasonItemViewModel?>

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.seasons, id: \.season.id) { seasonViewModel in
                        Button {
                            Text(seasonViewModel.season.displayTitle)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .if(selection.wrappedValue == seasonViewModel) { text in
                                    text
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                }
                        }
                        .buttonStyle(.card)
                        .focused($focusedSeason, equals: seasonViewModel)
                    }
                }
                .focusGuide(
                    focusGuide,
                    tag: "seasons",
                    onContentFocus: { focusedSeason = selection.wrappedValue },
                    top: "top",
                    bottom: "episodes"
                )
                .frame(height: 70)
                .padding(.horizontal, 50)
                .padding(.top)
                .padding(.bottom, 45)
            }
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
                guard let newValue else { return }
                selection.wrappedValue = newValue
            }
        }
    }
}
