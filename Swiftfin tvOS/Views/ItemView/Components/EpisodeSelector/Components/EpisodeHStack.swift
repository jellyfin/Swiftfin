//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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
        private var proxy = CollectionHStackProxy<BaseItemDto>()

        let playButtonItem: BaseItemDto?

        private func contentView(viewModel: SeasonItemViewModel) -> some View {
            CollectionHStack(
                $viewModel.elements,
                columns: 3.5
            ) { episode in
                SeriesEpisodeSelector.EpisodeCard(episode: episode)
                    .focused($focusedEpisodeID, equals: episode.id)
            }
            .scrollBehavior(.continuousLeadingEdge)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .proxy(proxy)
            .onFirstAppear {
                guard !didScrollToPlayButtonItem else { return }
                didScrollToPlayButtonItem = true

                lastFocusedEpisodeID = playButtonItem?.id

                // good enough?
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    guard let playButtonItem else { return }
                    proxy.scrollTo(element: playButtonItem, animated: false)
                }
            }
        }

        var body: some View {
            WrappedView {
                switch viewModel.state {
                case .content:
                    contentView(viewModel: viewModel)
                case let .error(error):
                    ErrorHStack(viewModel: viewModel, error: error)
                case .initial, .refreshing:
                    LoadingHStack()
                }
            }
            .focusSection()
            .focusGuide(
                focusGuide,
                tag: "episodes",
                onContentFocus: { focusedEpisodeID = lastFocusedEpisodeID },
                top: "seasons"
            )
            .onChange(of: viewModel) { _, newValue in
                lastFocusedEpisodeID = newValue.elements.first?.id
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

    struct ErrorHStack: View {

        @ObservedObject
        var viewModel: SeasonItemViewModel

        let error: JellyfinAPIError

        var body: some View {
            CollectionHStack(
                0 ..< 1,
                columns: 3.5
            ) { _ in
                SeriesEpisodeSelector.ErrorCard(error: error)
                    .onSelect {
                        viewModel.send(.refresh)
                    }
            }
            .allowScrolling(false)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
        }
    }

    struct LoadingHStack: View {

        var body: some View {
            CollectionHStack(
                0 ..< Int.random(in: 2 ..< 5),
                columns: 3.5
            ) { _ in
                SeriesEpisodeSelector.LoadingCard()
            }
            .allowScrolling(false)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
        }
    }
}
