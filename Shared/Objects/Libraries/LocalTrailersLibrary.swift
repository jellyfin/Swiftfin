//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct LocalTrailerLibrary: PagingLibrary {

    let parent: _TitledLibraryParent
    let hasNextPage: Bool = false

    init(parentID: String) {
        self.parent = .init(
            displayTitle: "",
            libraryID: parentID
        )
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        let request = Paths.getLocalTrailers(
            itemID: parent.libraryID,
            userID: pageState.userSession.user.id
        )
        let response = try await pageState.userSession.client.send(request)

        return response.value
    }
}
