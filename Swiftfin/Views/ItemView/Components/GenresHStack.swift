//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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
            ) { genre in
                let library = ItemLibrary(
                    parent: BaseItemDto(id: genre.value, name: genre.displayTitle),
                    filters: .init(genres: [genre])
                )
                router.route(to: .library(library: library))
            }
        }
    }
}
