//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension CollectionItemView {

    struct ContentView: View {

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: CollectionItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Genres

                if let genres = viewModel.item.genreItems, !genres.isEmpty {
                    PillHStack(
                        title: L10n.genres,
                        items: genres
                    ) { genre in
                        itemRouter.route(to: \.library, (viewModel: .init(genre: genre), title: genre.title))
                    }

                    Divider()
                }

                // MARK: Studios

                if let studios = viewModel.item.studios {
                    PillHStack(
                        title: L10n.studios,
                        items: studios
                    ) { studio in
                        itemRouter.route(to: \.library, (viewModel: .init(studio: studio), title: studio.name ?? ""))
                    }

                    Divider()
                }

                // MARK: Items

                if !viewModel.collectionItems.isEmpty {
                    PortraitPosterHStack(
                        title: L10n.items,
                        items: viewModel.collectionItems
                    ) { item in
                        itemRouter.route(to: \.item, item)
                    }
                }
            }
        }
    }
}
