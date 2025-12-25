//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct SimilarItemsLibrary: PagingLibrary {

    let itemID: String
    let parent: _TitledLibraryParent

    init(itemID: String) {
        self.itemID = itemID
        self.parent = .init(
            displayTitle: L10n.recommended,
            libraryID: "similar-items"
        )
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {

        var parameters = Paths.GetSimilarItemsParameters()
        parameters.limit = pageState.pageSize

        let request = Paths.getSimilarItems(
            itemID: itemID,
            parameters: parameters
        )
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
