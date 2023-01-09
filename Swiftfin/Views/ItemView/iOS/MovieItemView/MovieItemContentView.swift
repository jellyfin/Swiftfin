//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension MovieItemView {

    struct ContentView: View {

        @ObservedObject
        var viewModel: MovieItemViewModel

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

                // MARK: Special Features

                if !viewModel.specialFeatures.isEmpty {
                    ItemView.SpecialFeaturesHStack(items: viewModel.specialFeatures)

                    Divider()
                }

                // MARK: Similar

                if !viewModel.similarItems.isEmpty {
                    ItemView.SimilarItemsHStack(items: viewModel.similarItems)

                    Divider()
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
