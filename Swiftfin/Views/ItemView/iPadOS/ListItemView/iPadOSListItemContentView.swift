//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension iPadOSListItemView {

    struct ContentView: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: ListItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Items

                if viewModel.listItems.isNotEmpty {

                    ForEach(BaseItemKind.allCases, id: \.self) { sectionType in
                        let sectionItems = viewModel.listItems.filter { $0.type == sectionType }

                        if sectionItems.isNotEmpty {
                            PosterHStack(
                                // TODO: Is there a way to make this plural without creating a pluralDisplayTitle?
                                title: sectionType.displayTitle,
                                type: .portrait,
                                items: sectionItems
                            )
                            .trailing {
                                SeeAllButton()
                                    .onSelect {
                                        let viewModel = ItemLibraryViewModel(
                                            title: viewModel.item.displayTitle,
                                            id: viewModel.item.id,
                                            sectionItems
                                        )
                                        router.route(to: \.library, viewModel)
                                    }
                            }
                            .onSelect { item in
                                router.route(to: \.item, item)
                            }

                            RowDivider()
                        }
                    }
                }

                // MARK: Genres

                if let genres = viewModel.item.itemGenres, genres.isNotEmpty {
                    ItemView.GenresHStack(genres: genres)

                    RowDivider()
                }

                // MARK: Studios

                if let studios = viewModel.item.studios, studios.isNotEmpty {
                    ItemView.StudiosHStack(studios: studios)

                    RowDivider()
                }

                // MARK: Similar

                if viewModel.similarItems.isNotEmpty {
                    ItemView.SimilarItemsHStack(items: viewModel.similarItems)

                    RowDivider()
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
