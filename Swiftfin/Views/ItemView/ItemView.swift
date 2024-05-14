//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: try to make views simpler so there isn't one per media type, but per view type
//       - basic (episodes, collection) vs more fancy (rest)
//       - think about future for other media types

struct ItemView: View {

    @StateObject
    private var viewModel: ItemViewModel

    private static func typeViewModel(for item: BaseItemDto) -> ItemViewModel {
        switch item.type {
        case .boxSet:
            return CollectionItemViewModel(item: item)
        case .episode:
            return EpisodeItemViewModel(item: item)
        case .movie:
            return MovieItemViewModel(item: item)
        case .series:
            return SeriesItemViewModel(item: item)
        default:
            assertionFailure("Unsupported item")
            return ItemViewModel(item: item)
        }
    }

    init(item: BaseItemDto) {
        self._viewModel = StateObject(wrappedValue: Self.typeViewModel(for: item))
    }

    @ViewBuilder
    private var padView: some View {
        switch viewModel.item.type {
        case .boxSet:
            iPadOSCollectionItemView(viewModel: viewModel as! CollectionItemViewModel)
        case .episode:
            iPadOSEpisodeItemView(viewModel: viewModel as! EpisodeItemViewModel)
        case .movie:
            iPadOSMovieItemView(viewModel: viewModel as! MovieItemViewModel)
        case .series:
            iPadOSSeriesItemView(viewModel: viewModel as! SeriesItemViewModel)
        default:
            Text(L10n.notImplementedYetWithType(viewModel.item.type ?? "--"))
        }
    }

    @ViewBuilder
    private var phoneView: some View {
        switch viewModel.item.type {
        case .boxSet:
            CollectionItemView(viewModel: viewModel as! CollectionItemViewModel)
        case .episode:
            EpisodeItemView(viewModel: viewModel as! EpisodeItemViewModel)
        case .movie:
            MovieItemView(viewModel: viewModel as! MovieItemViewModel)
        case .series:
            SeriesItemView(viewModel: viewModel as! SeriesItemViewModel)
        default:
            Text(L10n.notImplementedYetWithType(viewModel.item.type ?? "--"))
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if UIDevice.isPad {
            padView
        } else {
            phoneView
        }
    }

    var body: some View {
        WrappedView {
            switch viewModel.state {
            case .content:
                contentView
                    .navigationTitle(viewModel.item.displayTitle)
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                DelayedProgressView()
            }
        }
        .transition(.opacity.animation(.linear(duration: 0.2)))
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.refresh) {
                ProgressView()
            }
        }
    }
}
