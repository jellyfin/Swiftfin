//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension PlaylistItemView {

    struct ContentView: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: PlaylistItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 20) {

                if viewModel.playlistItems.isNotEmpty {

                    ForEach(viewModel.playlistItems.keys, id: \.self) { itemType in
                        if let sectionItems = viewModel.playlistItems[itemType], sectionItems.isNotEmpty {
                            PosterHStack(
                                // TODO: Use DisplayTitle or PluralDisplayTitle
                                title: itemType.rawValue,
                                type: .portrait,
                                items: sectionItems
                            )
                            .onSelect { item in
                                router.route(to: \.item, item)
                            }
                            .trailing {
                                SeeAllButton()
                                    .onSelect {
                                        let viewModel = ItemLibraryViewModel(
                                            title: itemType.rawValue,
                                            id: viewModel.item.id,
                                            sectionItems
                                        )
                                        router.route(to: \.library, viewModel)
                                    }
                            }
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

                // MARK: Cast and Crew

                if let castAndCrew = viewModel.item.people,
                   castAndCrew.isNotEmpty
                {
                    ItemView.CastAndCrewHStack(people: castAndCrew)

                    RowDivider()
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
