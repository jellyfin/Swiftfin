//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

/// Requests return patches; only the accepting pager may publish them to the session store.
@MainActor
protocol MediaLibrary: PagingLibrary where Element == ItemEntry, PageElement == ItemPatch {}

@MainActor
extension MediaLibrary {
    func materialize(_ page: [ItemPatch], pageState: LibraryPageState) throws -> [ItemEntry] {
        try page.compactMap { patch in
            guard patch.value.id?.nilIfBlank != nil,
                  let record = try pageState.userSession.items.merge(patch, token: pageState.itemRequest)
            else { return nil }
            return ItemEntry(item: record, occurrence: patch.value.playlistItemID)
        }
    }
}

extension ItemStore {
    func results<Library: MediaLibrary>(
        for library: Library,
        pageSize: Int = defaultPagingLibraryPageSize
    ) -> PagingLibraryViewModel<Library> {
        PagingLibraryViewModel(library: library, pageSize: pageSize, userSession: session as? UserSession)
    }
}
