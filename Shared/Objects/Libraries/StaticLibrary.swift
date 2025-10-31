//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

struct StaticLibrary<Element: Poster>: PagingLibrary {

    let elements: [Element]
    let parent: _TitledLibraryParent
    let pages = false

    init(
        title: String,
        id: String,
        elements: [Element]
    ) {
        self.elements = elements
        self.parent = .init(
            displayTitle: title,
            libraryID: id,
        )
    }

    func retrievePage(
        environment: Void,
        pageState: LibraryPageState
    ) async throws -> [Element] {
        elements
    }
}
