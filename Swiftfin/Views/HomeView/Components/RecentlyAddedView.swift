//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension HomeView {

    struct RecentlyAddedView: View {

        @EnvironmentObject
        private var router: HomeCoordinator.Router
        @ObservedObject
        var viewModel: ItemTypeLibraryViewModel

        @Default(.Customization.recentlyAddedPosterType)
        private var recentlyAddedPosterType

        var body: some View {
            PosterHStack(
                title: L10n.recentlyAdded,
                type: recentlyAddedPosterType,
                items: viewModel.items.prefix(20).asArray
            )
            .trailing {
                SeeAllButton()
                    .onSelect {
                        router.route(to: \.basicLibrary, .init(title: L10n.recentlyAdded, viewModel: viewModel))
                    }
            }
            .onSelect { item in
                router.route(to: \.item, item)
            }
        }
    }
}
