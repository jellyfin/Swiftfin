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

    @MainActor
    static func contentGroup<Provider: _ContentGroupProvider>(
        provider: Provider
    ) -> NavigationRoute {
        NavigationRoute(
            id: "content-group-\(provider.id)",
            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
        ) {
            ContentGroupView(provider: provider)
        }
    }

    static func library<Library: PagingLibrary>(
        library: Library
    ) -> NavigationRoute where Library.Element: LibraryElement {
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
