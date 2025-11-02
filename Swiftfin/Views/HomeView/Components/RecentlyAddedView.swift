//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension HomeView {

    struct RecentlyAddedView: View {

        @Default(.Customization.recentlyAddedPosterType)
        private var recentlyAddedPosterType

        @Router
        private var router

        @ObservedObject
        var viewModel: RecentlyAddedLibraryViewModel

        var body: some View {
            if viewModel.elements.isNotEmpty {
                PosterHStack(
                    title: L10n.recentlyAdded.localizedCapitalized,
                    type: recentlyAddedPosterType,
                    items: viewModel.elements
                ) { item, namespace in
                    router.route(to: .item(item: item), in: namespace)
                }
                .trailing {
                    SeeAllButton()
                        .onSelect {
                            // Give a new view model becaues we don't want to
                            // keep paginated items on the home view model
                            let viewModel = RecentlyAddedLibraryViewModel()
                            router.route(to: .library(viewModel: viewModel))
                        }
                }
            }
        }
    }
}
