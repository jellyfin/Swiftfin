//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct StaticMediaLibrary: PagingLibrary {
    let elements: [ItemEntry]
    let hasNextPage = false
    let parent: TitledLibraryParent

    init(title: String, id: String, elements: [BaseItemDto]) {
        self.elements = elements.map { StoredItem(wrappedValue: $0).entry }
        self.parent = TitledLibraryParent(displayTitle: title, id: id)
    }

    func retrievePage(environment: Empty, pageState: LibraryPageState) async throws -> [ItemEntry] {
        elements.filter { $0.value != nil }
    }
}
