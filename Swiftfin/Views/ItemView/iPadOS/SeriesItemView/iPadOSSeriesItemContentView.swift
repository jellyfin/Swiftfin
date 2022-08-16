//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension iPadOSSeriesItemView {

    struct ContentView: View {

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: SeriesItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {

                // MARK: Episodes

                SeriesEpisodesView(viewModel: viewModel)

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

                if let studios = viewModel.item.studios, !studios.isEmpty {
                    PillHStack(
                        title: L10n.studios,
                        items: studios
                    ).onSelect { studio in
                        itemRouter.route(to: \.library, (viewModel: .init(studio: studio), title: studio.name ?? ""))
                    }

                    Divider()
                }

                // MARK: Cast and Crew

                if let castAndCrew = viewModel.item.people?.filter(\.isDisplayed),
                   !castAndCrew.isEmpty
                {
                    PosterHStack(title: L10n.castAndCrew, type: .portrait, items: castAndCrew)
                        .onSelect { person in
                            itemRouter.route(to: \.library, (viewModel: .init(person: person), title: person.title))
                        }

                    Divider()
                }

                // MARK: Similar

                if !viewModel.similarItems.isEmpty {
                    PosterHStack(title: L10n.recommended, type: .portrait, items: viewModel.similarItems)
                        .onSelect { item in
                            itemRouter.route(to: \.item, item)
                        }

                    Divider()
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
