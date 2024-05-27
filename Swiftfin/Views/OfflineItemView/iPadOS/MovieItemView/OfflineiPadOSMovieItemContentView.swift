//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension OfflineiPadOSMovieItemView {

    struct ContentView: View {

        @ObservedObject
        var viewModel: OfflineMovieItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {

                // MARK: Genres

                if let genres = viewModel.item.itemGenres, genres.isNotEmpty {
                    ItemView.GenresHStack(genres: genres)

                    RowDivider()
                }

                // MARK: Studios

                if let studios = viewModel.item.studios, studios.isNotEmpty {
                    OfflineItemView.StudiosHStack(studios: studios)

                    RowDivider()
                }

                OfflineItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
