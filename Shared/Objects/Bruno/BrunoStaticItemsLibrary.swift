//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// MARK: - BrunoStaticItemsLibrary

//
// A single-page `PagingLibrary` over an explicit, already-fetched item list. Used for synthetic
// collections that aren't backed by one server parent — e.g. "Boxed Sets" (a computed set of
// box sets) — so "Show all" can render them in the stock PagingLibraryView grid.
struct BrunoStaticItemsLibrary: BaseItemKindLibrary {

    let items: [BaseItemDto]
    let parent: TitledLibraryParent
    let hasNextPage: Bool = false

    var libraryItemTypes: [BaseItemKind] {
        [.boxSet]
    }

    init(items: [BaseItemDto], title: String, id: String) {
        self.items = items
        self.parent = .init(displayTitle: title, id: id)
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        pageState.pageOffset == 0 ? items : []
    }
}

// MARK: - NavigationRoute

extension NavigationRoute {

    @MainActor
    static func brunoItemsGrid(title: String, items: [BaseItemDto]) -> NavigationRoute {
        let id = "bruno-items-\(title.lowercased())"
        return NavigationRoute(
            id: id,
            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
        ) {
            PagingLibraryView(library: BrunoStaticItemsLibrary(items: items, title: title, id: id))
                .if(UIDevice.isTV) { view in
                    view.toolbar(.hidden, for: .navigationBar)
                }
        }
    }
}
