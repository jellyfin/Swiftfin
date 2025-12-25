//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct ParentalRatingLibrary: PagingLibrary {

    let parent: _TitledLibraryParent
    let hasNextPage: Bool = false

    init() {
        self.parent = .init(
            displayTitle: "",
            libraryID: "parental-ratings"
        )
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [ParentalRating] {
        let request = Paths.getParentalRatings
        let response = try await pageState.userSession.client.send(request)

        return response.value
    }
}
