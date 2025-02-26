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

    // MARK: - Focus States

    @FocusState
    private var focusedSection: String?

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
            } else {
                LoadingHStack(focusedEpisodeID: $focusedSection)
                    .environmentObject(parentFocusGuide)
                    .focused($focusedSection, equals: "LoadingCard")
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
        .onChange(of: selection) { _, _ in
            guard let selectionViewModel else { return }

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

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.seasons) { seasonViewModel in
                        Button {
                            Text(seasonViewModel.season.displayTitle)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .if(selection.wrappedValue == seasonViewModel.id) { text in
                                    text
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                }
                        }
                        .buttonStyle(.card)
                        .focused($focusedSeason, equals: seasonViewModel.id)
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
