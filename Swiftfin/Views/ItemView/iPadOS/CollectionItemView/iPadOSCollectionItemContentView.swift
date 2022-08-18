//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension iPadOSCollectionItemView {

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
                    ).onSelect { genre in
                        itemRouter.route(to: \.library, (viewModel: .init(genre: genre), title: genre.title))
                    }

                    Divider()
                }

                // MARK: Studios

                if let studios = viewModel.item.studios {
                    PillHStack(
                        title: L10n.studios,
                        items: studios
                    ).onSelect { studio in
                        itemRouter.route(to: \.library, (viewModel: .init(studio: studio), title: studio.name ?? ""))
                    }

                    Divider()
                }

                // MARK: Items

                if !viewModel.collectionItems.isEmpty {
                    PosterHStack(title: L10n.items, type: .portrait, items: viewModel.collectionItems)
                        .onSelect { item in
                            itemRouter.route(to: \.item, item)
                        }
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
