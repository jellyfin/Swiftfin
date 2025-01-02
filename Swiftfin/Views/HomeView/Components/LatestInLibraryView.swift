//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Defaults
import JellyfinAPI
import OrderedCollections
import SwiftUI

extension HomeView {

    struct LatestInLibraryView: View {

        @Default(.Customization.latestInLibraryPosterType)
        private var latestInLibraryPosterType

        @EnvironmentObject
        private var router: HomeCoordinator.Router

        @ObservedObject
        var viewModel: LatestInLibraryViewModel

        var body: some View {
            if viewModel.elements.isNotEmpty {
                PosterHStack(
                    title: L10n.latestWithString(viewModel.parent?.displayTitle ?? .emptyDash),
                    type: latestInLibraryPosterType,
                    items: viewModel.elements
                )
                .trailing {
                    SeeAllButton()
                        .onSelect {
                            router.route(to: \.library, viewModel)
                        }
                }
                .onSelect { item in
                    router.route(to: \.item, item)
                }
            }
        }
    }
}
