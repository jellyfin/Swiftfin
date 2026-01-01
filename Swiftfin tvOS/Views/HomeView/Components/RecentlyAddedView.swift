//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
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
                ) { item in
                    router.route(to: .item(item: item))
                }
            }
        }
    }
}
