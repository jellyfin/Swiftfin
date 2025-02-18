//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import Stinsen
import SwiftUI

struct MediaView: View {

    @EnvironmentObject
    private var router: MediaCoordinator.Router

    @StateObject
    private var viewModel = MediaViewModel()

    @ViewBuilder
    private var contentView: some View {
        CollectionVGrid(
            uniqueElements: viewModel.mediaItems,
            layout: .columns(4, insets: .init(50), itemSpacing: 50, lineSpacing: 50)
        ) { mediaType in
            MediaItem(viewModel: viewModel, type: mediaType)
                .onSelect {
                    switch mediaType {
                    case let .collectionFolder(item):
                        let viewModel = ItemLibraryViewModel(
                            parent: item,
                            filters: .default
                        )
                        router.route(to: \.library, viewModel)
                    case .downloads:
                        assertionFailure("Downloads unavailable on tvOS")
                    case .favorites:
                        let viewModel = ItemLibraryViewModel(
                            title: L10n.favorites,
                            id: "favorites",
                            filters: .favorites
                        )
                        router.route(to: \.library, viewModel)
                    case .liveTV:
                        router.route(to: \.liveTV)
                    }
                }
        }
    }

    var body: some View {
        ZStack {
            // This keeps the ErrorView vertically aligned with the PagingLibraryView
            Color.clear

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
        .ignoresSafeArea()
        .onFirstAppear {
            viewModel.send(.refresh)
        }
    }
}
