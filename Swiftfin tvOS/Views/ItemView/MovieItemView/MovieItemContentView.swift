//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension MovieItemView {

    struct ContentView: View {

        @ObservedObject
        var viewModel: MovieItemViewModel

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        var body: some View {
            VStack(spacing: 0) {

                ItemView.CinematicHeaderView(viewModel: viewModel)
                    .frame(height: UIScreen.main.bounds.height - 150)
                    .padding(.bottom, 50)

                if let castAndCrew = viewModel.item.people, castAndCrew.isNotEmpty {
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
            .background {
                BlurView(style: .dark)
                    .maskLinearGradient {
                        (location: 0.5, opacity: 0)
                        (location: 0.7, opacity: 0.8)
                        (location: 0.95, opacity: 0.8)
                        (location: 1, opacity: 1)
                    }
            }
        }
    }
}
