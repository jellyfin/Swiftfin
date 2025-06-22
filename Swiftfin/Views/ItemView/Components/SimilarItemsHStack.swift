//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import OrderedCollections
import SwiftUI

extension ItemView {

    struct SimilarItemsHStack: View {

        @Default(.Customization.similarPosterType)
        private var similarPosterType

        @Router
        private var router

        @StateObject
        private var viewModel: PagingLibraryViewModel<BaseItemDto>

        init(items: [BaseItemDto]) {
            self._viewModel = StateObject(wrappedValue: PagingLibraryViewModel(items, parent: BaseItemDto(name: L10n.recommended)))
        }

        var body: some View {
            PosterHStack(
                title: L10n.recommended,
                type: similarPosterType,
                items: viewModel.elements
            )
            .trailing {
                SeeAllButton()
                    .onSelect {
                        router.route(to: .library(viewModel: viewModel))
                    }
            }
            .onSelect { item in
                router.route(to: .item(item: item))
            }
        }
    }
}
