//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Foundation
import JellyfinAPI
import SwiftUI

extension SeriesEpisodeSelector {

    struct EpisodeHStack: View {

        @EnvironmentObject
        private var focusGuide: FocusGuide

        @FocusState
        private var focusedEpisodeID: String?

        @ObservedObject
        var viewModel: SeasonItemViewModel

        @State
        private var didScrollToPlayButtonItem = false
        @State
        private var lastFocusedEpisodeID: String?

        @StateObject
        private var proxy = CollectionHStackProxy()

        let playButtonItem: BaseItemDto?

        // MARK: - Content View

        private func contentView(viewModel: SeasonItemViewModel) -> some View {
            CollectionHStack(
                uniqueElements: viewModel.elements,
                id: \.unwrappedIDHashOrZero,
                columns: 3.5
            ) { episode in
                SeriesEpisodeSelector.EpisodeCard(episode: episode)
                    .focused($focusedEpisodeID, equals: episode.id)
                    .padding(.horizontal, 4)
            }
            .scrollBehavior(.continuousLeadingEdge)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .proxy(proxy)
            .onFirstAppear {
                guard !didScrollToPlayButtonItem else { return }
                didScrollToPlayButtonItem = true

                lastFocusedEpisodeID = playButtonItem?.id

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    guard let playButtonItem else { return }
                    proxy.scrollTo(id: playButtonItem.unwrappedIDHashOrZero, animated: false)
                }
            }
        }

        // MARK: - Determine Which Episode should be Focused

        private func getContentFocus() {
            switch viewModel.state {
            case .content:
                if viewModel.elements.isEmpty {
                    /// Focus the EmptyCard if the Season has no elements
                    focusedEpisodeID = "emptyCard"
                } else {
                    if let lastFocusedEpisodeID,
                       viewModel.elements.contains(where: { $0.id == lastFocusedEpisodeID })
                    {
                        /// Return focus to the Last Focused Episode if it exists in the current Season
                        focusedEpisodeID = lastFocusedEpisodeID
                    } else {
                        /// Focus the First Episode in the season as a last resort
                        focusedEpisodeID = viewModel.elements.first?.id
                    }
                }
            case .error:
                /// Focus the ErrorCard if the Season failed to load
                focusedEpisodeID = "errorCard"
            case .initial, .refreshing:
                /// Focus the LoadingCard if the Season is currently loading
                focusedEpisodeID = "loadingCard"
            }
        }

        // MARK: - Body

        var body: some View {
            ZStack {
                PlaceholderHStack()

                Group {
                    switch viewModel.state {
                    case .content:
                        if viewModel.elements.isEmpty {
                            EmptyHStack(focusedEpisodeID: $focusedEpisodeID)
                        } else {
                            contentView(viewModel: viewModel)
                        }
                    case let .error(error):
                        ErrorHStack(viewModel: viewModel, error: error, focusedEpisodeID: $focusedEpisodeID)
                    case .initial, .refreshing:
                        LoadingHStack(focusedEpisodeID: $focusedEpisodeID)
                    }
                }.transition(.opacity.animation(.linear(duration: 0.1)))
            }
            .padding(.bottom, 45)
            .focusSection()
            .focusGuide(
                focusGuide,
                tag: "episodes",
                onContentFocus: {
                    getContentFocus()
                },
                top: "belowHeader"
            )
            .onChange(of: viewModel.id) {
                lastFocusedEpisodeID = viewModel.elements.first?.id
            }
            .onChange(of: focusedEpisodeID) { _, newValue in
                guard let newValue else { return }
                lastFocusedEpisodeID = newValue
            }
            .onChange(of: viewModel.state) { _, newValue in
                if newValue == .content {
                    lastFocusedEpisodeID = viewModel.elements.first?.id
                }
            }
        }
    }

    // MARK: - Empty HStack

    struct EmptyHStack: View {

        let focusedEpisodeID: FocusState<String?>.Binding

        var body: some View {
            CollectionHStack(
                count: 1,
                columns: 3.5
            ) { _ in
                SeriesEpisodeSelector.EmptyCard()
                    .focused(focusedEpisodeID, equals: "emptyCard")
                    .padding(.horizontal, 4)
            }
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollDisabled(true)
        }
    }

    // MARK: - Error HStack

    struct ErrorHStack: View {

        @ObservedObject
        var viewModel: SeasonItemViewModel

        let error: ErrorMessage
        let focusedEpisodeID: FocusState<String?>.Binding

        var body: some View {
            CollectionHStack(
                count: 1,
                columns: 3.5
            ) { _ in
                SeriesEpisodeSelector.ErrorCard(error: error)
                    .onSelect {
                        viewModel.send(.refresh)
                    }
                    .focused(focusedEpisodeID, equals: "errorCard")
                    .padding(.horizontal, 4)
            }
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollDisabled(true)
        }
    }

    // MARK: - Loading HStack

    struct LoadingHStack: View {

        let focusedEpisodeID: FocusState<String?>.Binding

        var body: some View {
            CollectionHStack(
                count: 1,
                columns: 3.5
            ) { _ in
                SeriesEpisodeSelector.LoadingCard()
                    .focused(focusedEpisodeID, equals: "loadingCard")
                    .padding(.horizontal, 4)
            }
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollDisabled(true)
        }
    }

    // MARK: - Placeholder HStack

    struct PlaceholderHStack: View {

        var body: some View {
            CollectionHStack(
                count: 1,
                columns: 3.5
            ) { _ in
                SeriesEpisodeSelector.EmptyCard()
                    .padding(.horizontal, 4)
            }
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .opacity(0)
            .allowsHitTesting(false)
            .scrollDisabled(true)
        }
    }
}
