//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct LocalTrailerLibrary: PagingLibrary {

    let parent: BaseItemDto
    let hasNextPage: Bool = false

    init(parent: BaseItemDto) {
        self.parent = parent
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        guard let itemID = parent.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        let request = Paths.getLocalTrailers(itemID: itemID, userID: pageState.userSession.user.id)
        let response = try await pageState.userSession.client.send(request)

        return response.value
    }
}
