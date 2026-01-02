//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemView: View {

    protocol ScrollContainerView: View {

        associatedtype Content: View

        init(viewModel: ItemViewModel, content: @escaping () -> Content)
    }

    @StateObject
    private var viewModel: ItemViewModel

    // MARK: typeViewModel

    private static func typeViewModel(for item: BaseItemDto) -> ItemViewModel {
        switch item.type {
        case .boxSet, .person, .musicArtist:
            return CollectionItemViewModel(item: item)
        case .episode:
            return EpisodeItemViewModel(item: item)
        case .movie:
            return MovieItemViewModel(item: item)
        case .musicVideo, .video:
            return ItemViewModel(item: item)
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
    private var scrollContentView: some View {
        switch viewModel.item.type {
        case .boxSet, .person, .musicArtist:
            CollectionItemContentView(viewModel: viewModel as! CollectionItemViewModel)
        case .episode, .musicVideo, .video:
            SimpleItemContentView(viewModel: viewModel)
        case .movie:
            MovieItemContentView(viewModel: viewModel as! MovieItemViewModel)
        case .series:
            SeriesItemContentView(viewModel: viewModel as! SeriesItemViewModel)
        default:
            Text(L10n.notImplementedYetWithType(viewModel.item.type ?? "--"))
        }
    }

    // MARK: scrollContainerView

    private func scrollContainerView<Content: View>(
        viewModel: ItemViewModel,
        content: @escaping () -> Content
    ) -> any ScrollContainerView {
        CinematicScrollView(viewModel: viewModel, content: content)
    }

    @ViewBuilder
    private var innerBody: some View {
        scrollContainerView(viewModel: viewModel) {
            scrollContentView
        }
        .eraseToAnyView()
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                innerBody
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .refreshable {
            viewModel.send(.refresh)
        }
    }
}
