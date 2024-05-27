//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension OfflineiPadOSEpisodeItemView {

    struct ContentView: View {

        @EnvironmentObject
        private var router: OfflineItemCoordinator.Router

        @ObservedObject
        var viewModel: OfflineEpisodeItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {

                // MARK: Genres

                if let genres = viewModel.item.itemGenres, genres.isNotEmpty {
                    OfflineItemView.GenresHStack(genres: genres)

                    RowDivider()
                }

                // MARK: Studios

                if let studios = viewModel.item.studios, studios.isNotEmpty {
                    OfflineItemView.StudiosHStack(studios: studios)

                    RowDivider()
                }

                // MARK: Series

                if let seriesItem = viewModel.seriesItem {
                    PosterHStack(
                        title: L10n.series,
                        type: .portrait,
                        items: [seriesItem]
                    )
                    .onSelect { item in
                        router.route(to: \.item, item)
                    }
                }

                OfflineItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
