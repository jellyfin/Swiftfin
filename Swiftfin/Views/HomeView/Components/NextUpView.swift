//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Defaults
import JellyfinAPI
import SwiftUI

extension HomeView {

    struct NextUpView: View {

        @Default(.Customization.nextUpPosterType)
        private var nextUpPosterType

        @EnvironmentObject
        private var router: HomeCoordinator.Router

        @ObservedObject
        var homeViewModel: HomeViewModel

        var body: some View {
            if homeViewModel.nextUpViewModel.elements.isNotEmpty {
                PosterHStack(
                    title: L10n.nextUp,
                    type: nextUpPosterType,
                    items: $homeViewModel.nextUpViewModel.elements
                )
                .trailing {
                    SeeAllButton()
                        .onSelect {
                            router.route(to: \.library, homeViewModel.nextUpViewModel)
                        }
                }
                .contextMenu { item in
                    Button {
                        homeViewModel.send(.setIsPlayed(true, item))
                    } label: {
                        Label(L10n.played, systemImage: "checkmark.circle")
                    }
                }
                .onSelect { item in
                    router.route(to: \.item, item)
                }
            }
        }
    }
}
