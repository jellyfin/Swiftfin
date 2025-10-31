//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import Engine
import JellyfinAPI
import SwiftUI

struct MediaView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = MediaViewModel()

    private var layout: CollectionVGridLayout {
        if UIDevice.isTV {
            .columns(4, insets: .init(50), itemSpacing: 50, lineSpacing: 50)
        } else if UIDevice.isPad {
            .minWidth(200)
        } else {
            .columns(2)
        }
    }

    @ViewBuilder
    private var content: some View {
        CollectionVGrid(
            uniqueElements: viewModel.mediaItems,
            layout: layout
        ) { mediaType in
            MediaItem(viewModel: viewModel, type: mediaType) { namespace in
                switch mediaType {
                case let .collectionFolder(item):
                    let pagingLibrary = PagingItemLibrary(parent: item)
                    router.route(to: .library(library: pagingLibrary), in: namespace)
                case .downloads:
                    router.route(to: .downloadList)
                case .favorites:
                    router.route(
                        to: .contentGroup(
                            provider: FavoritesContentGroupProvider()
                        ),
                        in: namespace
                    )
                case .liveTV:
                    router.route(to: .liveTV, in: namespace)
                }
            }
        }
    }

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.refresh()
            }
    }

    var body: some View {
        ZStack {
            Color.clear

            switch viewModel.state {
            case .initial:
                content
            case .error:
                viewModel.error.map { errorView(with: $0) }
            case .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .ignoresSafeArea()
        .navigationTitle(L10n.allMedia)
        .onFirstAppear {
            viewModel.refresh()
        }
        .if(UIDevice.isTV) { view in
            view.toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct FavoritesContentGroupProvider: _ContentGroupProvider {

    let displayTitle: String = L10n.favorites
    let id: String = "favorites-content-group-provider"
    let systemImage: String = "heart.fill"

    func makeGroups(environment: ()) async throws -> [any _ContentGroup] {
        try await ItemTypeContentGroupProvider(
            itemTypes: [
                BaseItemKind.movie,
                .series,
                .boxSet,
                .episode,
                .musicVideo,
                .video,
                .liveTvProgram,
                .tvChannel,
                .musicArtist,
                .person,
            ]
        )
        .makeGroups(environment: .init(filters: .favorites))
    }
}
