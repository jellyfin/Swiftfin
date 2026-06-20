//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension NavigationRoute {

    static func filter(type: ItemFilterType, viewModel: FilterViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "filter",
            style: .sheet
        ) {
            FilterView(
                viewModel: viewModel,
                type: type
            )
        }
    }

    @MainActor
    static func library<Library: PagingLibrary>(
        library: Library
    ) -> NavigationRoute where Library.Element: LibraryElement {
        NavigationRoute(
            id: "library-\(library.parent.pagingLibraryID)",
            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
        ) {
            PagingLibraryView(library: library)
        }
    }
}
