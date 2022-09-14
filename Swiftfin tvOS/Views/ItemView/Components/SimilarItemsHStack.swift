//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct SimilarItemsHStack: View {

        @Default(.Customization.similarPosterType)
        private var similarPosterType

        @EnvironmentObject
        private var router: ItemCoordinator.Router
        let items: [BaseItemDto]

        var body: some View {
            PosterHStack(
                title: L10n.recommended,
                type: similarPosterType,
                items: items
            )
            .trailing {
                SeeAllPoster(type: similarPosterType)
                    .onSelect {
                        let viewModel = StaticLibraryViewModel(items: items)
                        router.route(to: \.basicLibrary, .init(title: L10n.recommended, viewModel: viewModel))
                    }
            }
            .onSelect { item in
                router.route(to: \.item, item)
            }
        }
    }
}
