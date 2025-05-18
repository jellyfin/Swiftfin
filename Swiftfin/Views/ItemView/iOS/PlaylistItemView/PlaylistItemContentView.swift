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

                // MARK: Playlist Items by Type

                ForEach(viewModel.playlistItems.elements, id: \.key) { element in
                    if element.value.isNotEmpty {
                        PosterHStack(
                            title: element.key.pluralDisplayTitle,
                            type: .portrait,
                            items: element.value
                        )
                        .trailing {
                            SeeAllButton()
                                .onSelect {
                                    let viewModel = ItemLibraryViewModel(
                                        title: viewModel.item.displayTitle,
                                        id: viewModel.item.id,
                                        element.value
                                    )
                                    router.route(to: \.library, viewModel)
                                }
                        }
                        .onSelect { item in
                            router.route(to: \.item, item)
                        }
                        /* TODO: Enable when Playlist Editing is Available
                         .contextMenu { _ in
                             Button(role: .destructive) {
                                 editorViewModel.send(removeFromPlaylist)
                             } label: {
                                 Label("Remove from playlist", systemImage: "text.badge.minus")
                             }
                         }*/

                        RowDivider()
                    }
                }

                // MARK: Genres

                if let genres = viewModel.item.itemGenres, genres.isNotEmpty {
                    ItemView.GenresHStack(genres: genres)

                    RowDivider()
                }

                // MARK: About

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
