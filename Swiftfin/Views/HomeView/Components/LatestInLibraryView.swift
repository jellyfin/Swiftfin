//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CongruentScrollingHStack
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
        var viewModel: LibraryViewModel
        
        @State
        private var prefixedItems: OrderedSet<BaseItemDto> = []

        var body: some View {
            CongruentScrollingHStack(
                items: $viewModel.items,
                columns: 3,
                scrollBehavior: .continuousLeadingEdge
            ) { item in
                PosterButton(item: item, type: .portrait)
                    .onSelect {
                        router.route(to: \.item, item)
                    }
            }
            .onChange(of: viewModel.items) { newValue in
                prefixedItems.elements = newValue
                    .prefix(20)
                    .asArray
            }
            
//            PosterHStack(
//                title: L10n.latestWithString(viewModel.parent?.displayTitle ?? .emptyDash),
//                type: latestInLibraryPosterType,
//                items: items
//            )
//            .trailing {
//                SeeAllButton()
//                    .onSelect {
//                        router.route(to: \.library, viewModel.libraryCoordinatorParameters)
//                    }
//            }
//            .onSelect { item in
//                router.route(to: \.item, item)
//            }
        }
    }
}
