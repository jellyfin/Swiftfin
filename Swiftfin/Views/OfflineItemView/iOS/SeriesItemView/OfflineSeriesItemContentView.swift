//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension OfflineSeriesItemView {

    struct ContentView: View {
        @ObservedObject
        var offlineViewModel: OfflineViewModel
        @ObservedObject
        var viewModel: OfflineSeriesItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Episodes

                if viewModel.seasons.isNotEmpty {
                    OfflineSeriesEpisodeSelector(viewModel: viewModel, offlineViewModel: offlineViewModel)
                }

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

                // MARK: Similar

                if viewModel.similarItems.isNotEmpty {
                    OfflineItemView.SimilarItemsHStack(items: viewModel.similarItems)

                    RowDivider()
                }

                OfflineItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
