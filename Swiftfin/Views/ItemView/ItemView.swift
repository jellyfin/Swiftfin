//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ItemView: View {

    protocol ScrollContainerView: View {

        associatedtype Content: View

        init(viewModel: ItemViewModel, content: @escaping () -> Content)
    }

    @Default(.Customization.itemViewType)
    private var itemViewType

    @Router
    private var router

    @StateObject
    private var viewModel: ItemViewModel

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

    // TODO: break out into pad vs phone views based on item type
    private func scrollContainerView<Content: View>(
        viewModel: ItemViewModel,
        content: @escaping () -> Content
    ) -> any ScrollContainerView {

        if UIDevice.isPad {
            return iPadOSCinematicScrollView(viewModel: viewModel, content: content)
        }

        switch viewModel.item.type {
        case .movie, .series:
            switch itemViewType {
            case .compactPoster:
                return CompactPosterScrollView(viewModel: viewModel, content: content)
            case .compactLogo:
                return CompactLogoScrollView(viewModel: viewModel, content: content)
            case .cinematic:
                return CinematicScrollView(viewModel: viewModel, content: content)
            }
        case .person, .musicArtist:
            return CompactPosterScrollView(viewModel: viewModel, content: content)
        default:
            return SimpleScrollView(viewModel: viewModel, content: content)
        }
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
                    .navigationTitle(viewModel.item.displayTitle)
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.send(.refresh)
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .navigationBarMenuButton(
            isLoading: viewModel.backgroundStates.contains(.refresh),
            isHidden: !viewModel.item.showEditorMenu
        ) {
            ItemEditorMenu(item: viewModel.item)
        }
    }
}
