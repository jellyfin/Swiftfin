//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension CollectionItemView {

    struct ContentView: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: CollectionItemViewModel

        private var items: [PosterButtonType<BaseItemDto>] {
            if viewModel.isLoading {
                return PosterButtonType.loading.random(in: 3 ..< 8)
            } else {
                return viewModel.collectionItems.map { .item($0) }
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Genres

                if let genres = viewModel.item.genreItems, !genres.isEmpty {
                    ItemView.GenresHStack(genres: genres)

                    Divider()
                }

                // MARK: Studios

                if let studios = viewModel.item.studios, !studios.isEmpty {
                    ItemView.StudiosHStack(studios: studios)

                    Divider()
                }

                // MARK: Items

                PosterHStack(
                    title: L10n.items,
                    type: .portrait,
                    items: items
                )
                .onSelect { item in
                    router.route(to: \.item, item)
                }
            }
        }
    }
}
