//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct GenresHStack: View {

        @Router
        private var router

        let genres: [ItemGenre]

        var body: some View {
            PillHStack(
                title: L10n.genres,
                items: genres
            ).onSelect { _ in
//                let library = PagingItemLibrary(
//                    parent: genre,
//                    filters: .init(parent: nil, currentFilters: .init(genres: [genre]))
//                )
//
//                router.route(to: .library(library: library))
            }
        }
    }
}

// extension ItemGenre: _LibraryParent {
//    var libraryID: String { value }
// }
