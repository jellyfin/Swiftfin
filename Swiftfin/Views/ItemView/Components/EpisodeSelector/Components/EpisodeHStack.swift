//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Foundation
import JellyfinAPI
import SwiftUI

// TODO: The content/loading/error states are implemented as different CollectionHStacks because it was just easy.
//       A theoretically better implementation would be a single CollectionHStack with cards that represent the state instead.
extension SeriesEpisodeSelector {

    struct EpisodeHStack: View {

        @ObservedObject
        var viewModel: SeasonItemViewModel

        @State
        private var didScrollToPlayButtonItem = false

        @StateObject
        private var proxy = CollectionHStackProxy()

        let playButtonItem: BaseItemDto?

        private func contentView(viewModel: SeasonItemViewModel) -> some View {
            CollectionHStack(
                uniqueElements: viewModel.elements,
                id: \.unwrappedIDHashOrZero,
                columns: UIDevice.isPhone ? 1.5 : 3.5
            ) { episode in
                SeriesEpisodeSelector.EpisodeCard(episode: episode)
            }
            .scrollBehavior(.continuousLeadingEdge)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .proxy(proxy)
            .onFirstAppear {
                guard !didScrollToPlayButtonItem else { return }
                didScrollToPlayButtonItem = true

                // good enough?
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    guard let playButtonItem else { return }
                    proxy.scrollTo(element: playButtonItem, animated: false)
                }
            }
        }

        var body: some View {
            switch viewModel.state {
            case .content:
                if viewModel.elements.isEmpty {
                    EmptyHStack()
                } else {
                    contentView(viewModel: viewModel)
                }
            case let .error(error):
                ErrorHStack(viewModel: viewModel, error: error)
            case .initial, .refreshing:
                LoadingHStack()
            }
        }
    }

    struct EmptyHStack: View {

        var body: some View {
            CollectionHStack(
                count: 1,
                columns: UIDevice.isPhone ? 1.5 : 3.5
            ) { _ in
                SeriesEpisodeSelector.EmptyCard()
            }
            .allowScrolling(false)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
        }
    }

    // TODO: better refresh design
    struct ErrorHStack: View {

        @ObservedObject
        var viewModel: SeasonItemViewModel

        let error: JellyfinAPIError

        var body: some View {
            CollectionHStack(
                count: 1,
                columns: UIDevice.isPhone ? 1.5 : 3.5
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
                count: Int.random(in: 2 ..< 5),
                columns: UIDevice.isPhone ? 1.5 : 3.5
            ) { _ in
                SeriesEpisodeSelector.LoadingCard()
            }
            .allowScrolling(false)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
        }
    }
}
