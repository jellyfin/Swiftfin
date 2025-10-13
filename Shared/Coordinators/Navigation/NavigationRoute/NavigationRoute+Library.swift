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

    #if os(iOS)
    static func filter(type: ItemFilterType, viewModel: FilterViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "filter",
            style: .sheet
        ) {
            FilterView(viewModel: viewModel, type: type)
        }
    }
    #endif

//    static func library(
//        viewModel: PagingLibraryViewModel<some Poster>
//    ) -> NavigationRoute {
//        NavigationRoute(
//            id: "library-(\(viewModel.parent?.id ?? "Unparented"))",
//            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
//        ) {
//            PagingLibraryView(viewModel: viewModel)
//        }
//    }

    static func library<Library: PagingLibrary>(
        library: Library
    ) -> NavigationRoute where Library.Element: Poster, Library.Element.Environment == Void {
        NavigationRoute(
            id: "library-\(library.parent.libraryID)",
            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
        ) {
            PagingLibraryView(library: library)
        }
    }

    static func posterGroupPosterButtonStyle(id: String) -> NavigationRoute {
        NavigationRoute(
            id: "poster-group-poster-button-style-\(id)",
            style: .sheet
        ) {
            CustomizePosterGroupSettings(id: id)
        }
    }
}
