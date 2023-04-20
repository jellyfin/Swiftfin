//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension iPadOSEpisodeItemView {

    struct ContentView: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: EpisodeItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {

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

                // MARK: Cast and Crew

                if let castAndCrew = viewModel.item.people,
                   !castAndCrew.isEmpty
                {
                    ItemView.CastAndCrewHStack(people: castAndCrew)

                    Divider()
                }

                // MARK: Series

                if let seriesItem = viewModel.seriesItem {
                    PosterHStack(title: L10n.series, type: .portrait, items: [seriesItem])
                        .onSelect { item in
                            router.route(to: \.item, item)
                        }
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
