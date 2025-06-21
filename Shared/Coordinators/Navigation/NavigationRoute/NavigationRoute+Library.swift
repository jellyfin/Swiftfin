//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension NavigationRoute {

    #if !os(tvOS)
    static func filter(type: ItemFilterType, viewModel: FilterViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "filter",
            routeType: .sheet
        ) {
            FilterView(viewModel: viewModel, type: type)
        }
    }
    #endif

    static func library<Element: Poster>(viewModel: PagingLibraryViewModel<Element>) -> NavigationRoute {
        NavigationRoute(id: "library") {
            PagingLibraryView(viewModel: viewModel)
        }
    }
}
