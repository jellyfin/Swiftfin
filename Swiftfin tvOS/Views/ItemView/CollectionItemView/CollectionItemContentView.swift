//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension CollectionItemView {

    struct ContentView: View {

        @ObservedObject
        var viewModel: CollectionItemViewModel

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        var body: some View {
            VStack(spacing: 0) {

                ItemView.CinematicHeaderView(viewModel: viewModel)
                    .frame(height: UIScreen.main.bounds.height - 150)
                    .padding(.bottom, 50)

                ForEach(viewModel.collectionItems.elements, id: \.key) { element in
                    if element.value.isNotEmpty {
                        PosterHStack(
                            title: element.key.pluralDisplayTitle,
                            type: .portrait,
                            items: element.value
                        )
                        .onSelect { item in
                            router.route(to: \.item, item)
                        }
                    }
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
