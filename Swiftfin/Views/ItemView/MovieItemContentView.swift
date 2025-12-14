//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct MovieItemContentView: View {

        @ObservedObject
        var viewModel: MovieItemViewModel

        var body: some View {
            SeparatorVStack(alignment: .leading) {
                RowDivider()
                    .padding(.vertical, 10)
            } content: {

                if let genres = viewModel.item.itemGenres, genres.isNotEmpty {
                    ItemView.GenresHStack(genres: genres)
                }

                if let studios = viewModel.item.studios, studios.isNotEmpty {
                    ItemView.StudiosHStack(studios: studios)
                }

                // TODO: Implement after part queue made
//                if viewModel.additionalParts.isNotEmpty {
//                    AdditionalPartsHStack(items: viewModel.additionalParts)
//                }

                if let castAndCrew = viewModel.item.people,
                   castAndCrew.isNotEmpty
                {
                    ItemView.CastAndCrewHStack(people: castAndCrew)
                }

                if viewModel.specialFeatures.isNotEmpty {
                    ItemView.SpecialFeaturesHStack(items: viewModel.specialFeatures)
                }

                if viewModel.similarItems.isNotEmpty {
                    ItemView.SimilarItemsHStack(items: viewModel.similarItems)
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
