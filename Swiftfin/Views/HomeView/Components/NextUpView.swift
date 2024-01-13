//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

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
        var viewModel: NextUpLibraryViewModel

        private var items: [BaseItemDto] {
            viewModel.items.prefix(20).asArray
        }

        var body: some View {
            PosterHStack(
                title: L10n.nextUp,
                type: nextUpPosterType,
                items: items
            )
            .trailing {
                SeeAllButton()
                    .onSelect {
                        router.route(to: \.basicLibrary, .init(title: L10n.nextUp, viewModel: viewModel))
                    }
            }
            .contextMenu { item in
                Button {
                    viewModel.markPlayed(item: item)
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
