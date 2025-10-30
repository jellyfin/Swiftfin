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

        @Router
        private var router

        let items: [BaseItemDto]

        var body: some View {
            WithPosterButtonStyle(id: "recommended") {
                PosterHStack(
                    title: L10n.recommended,
                    elements: items,
                    type: .portrait
                ) { item, namespace in
                    router.route(to: .item(item: item), in: namespace)
                }
//                .trailing {
//                    SeeAllButton()
//                        .onSelect {
//                            let library = StaticLibrary(
//                                title: L10n.recommended,
//                                id: "recommended",
//                                elements: items
//                            )
//                            router.route(to: .library(library: library))
//                        }
//                }
            }
        }
    }
}
