//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
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
    static func savedFilterEditor(viewModel: FilterViewModel) -> NavigationRoute {
        let savedFilter = viewModel.selectedSavedFilter

        return NavigationRoute(
            id: "saved-filter-editor",
            style: .sheet
        ) {
            SavedFilterEditorView(
                viewModel: viewModel,
                name: savedFilter?.name ?? "",
                grouping: savedFilter == nil ? viewModel.grouping : savedFilter?.grouping,
                posterDisplayType: savedFilter?.posterDisplayType ?? Defaults[.Customization.Library.style].posterDisplayType,
                isPinned: savedFilter.map { Defaults[.Customization.Home.pinnedFilters].contains($0.id) } ?? false,
                savedFilter: savedFilter
            )
        }
    }

    @MainActor
    static func contentGroup(
        provider: some ContentGroupProvider
    ) -> NavigationRoute {
        NavigationRoute(
            id: "content-group-\(provider.id)",
            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
        ) {
            ContentGroupView(provider: provider)
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
