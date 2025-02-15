//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

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
    private var contentView: some View {
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

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
                    .onRetry {
                        viewModel.send(.refresh)
                    }
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .onFirstAppear {
            viewModel.send(.refresh)
        }
    }
}
