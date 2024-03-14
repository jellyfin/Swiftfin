//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Introspect
import JellyfinAPI
import SwiftUI

struct SeriesEpisodeSelector: View {

    @ObservedObject
    var viewModel: SeriesItemViewModel

    @EnvironmentObject
    private var parentFocusGuide: FocusGuide

    var body: some View {
        VStack(spacing: 0) {
            SeasonsHStack(viewModel: viewModel)
                .environmentObject(parentFocusGuide)

            EpisodesHStack(viewModel: viewModel)
                .environmentObject(parentFocusGuide)
        }
    }
}

extension SeriesEpisodeSelector {

    // MARK: SeasonsHStack

    struct SeasonsHStack: View {

        @ObservedObject
        var viewModel: SeriesItemViewModel

        @EnvironmentObject
        private var focusGuide: FocusGuide

        @FocusState
        private var focusedSeason: BaseItemDto?

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.menuSections.keys.sorted(by: { viewModel.menuSectionSort($0, $1) }), id: \.self) { season in
                        Button {
                            Text(season.displayTitle)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .if(viewModel.menuSelection == season) { text in
                                    text
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                }
                        }
                        .buttonStyle(.card)
                        .focused($focusedSeason, equals: season)
                    }
                }
                .focusGuide(
                    focusGuide,
                    tag: "seasons",
                    onContentFocus: { focusedSeason = viewModel.menuSelection },
                    top: "top",
                    bottom: "episodes"
                )
                .frame(height: 70)
                .padding(.horizontal, 50)
                .padding(.top)
                .padding(.bottom, 45)
            }
            .onChange(of: focusedSeason) { season in
                guard let season = season else { return }
                viewModel.select(section: season)
            }
        }
    }
}

extension SeriesEpisodeSelector {

    // MARK: EpisodesHStack

    struct EpisodesHStack: View {

        @ObservedObject
        var viewModel: SeriesItemViewModel

        @EnvironmentObject
        private var focusGuide: FocusGuide
        @FocusState
        private var focusedEpisodeID: String?
        @State
        private var lastFocusedEpisodeID: String?
        @State
        private var wrappedScrollView: UIScrollView?

        var contentView: some View {
            CollectionHStack(
                $viewModel.currentItems,
                columns: 3.5
            ) { item in
                EpisodeCard(episode: item)
                    .focused($focusedEpisodeID, equals: item.id)
            }
            .insets(vertical: 20)
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
            .transition(.opacity)
            .focusSection()
            .focusGuide(
                focusGuide,
                tag: "episodes",
                onContentFocus: { focusedEpisodeID = lastFocusedEpisodeID },
                top: "seasons"
            )
            .onChange(of: viewModel.menuSelection) { _ in
                lastFocusedEpisodeID = viewModel.currentItems.first?.id
            }
            .onChange(of: focusedEpisodeID) { episodeIndex in
                guard let episodeIndex = episodeIndex else { return }
                lastFocusedEpisodeID = episodeIndex
            }
            .onChange(of: viewModel.currentItems) { _ in
                lastFocusedEpisodeID = viewModel.currentItems.first?.id
            }
        }

        var body: some View {
            if viewModel.currentItems.isEmpty {
                EmptyView()
            } else {
                contentView
            }
        }
    }
}
