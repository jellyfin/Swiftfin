//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// MARK: - BrunoQueryLibrary

//
// A `BaseItemKindLibrary` (the same shape as `RecentlyAddedLibrary`) that realises a
// `BrunoQuery` into a `GetItems` request, then applies the query's client-side seeded
// shuffle so the shelf is reproducible (plan §D — server sort stays stable, the shuffle
// provides the "seeded" ordering). One page covers a shelf; we don't paginate Bruno rows.
struct BrunoQueryLibrary: BaseItemKindLibrary {

    let query: BrunoQuery
    let parent: TitledLibraryParent

    var libraryItemTypes: [BaseItemKind] {
        query.includeItemTypes
    }

    init(query: BrunoQuery, displayTitle: String, id: String) {
        self.query = query
        self.parent = .init(displayTitle: displayTitle, id: id)
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetItemsParameters()
        parameters.userID = pageState.userSession.user.id
        parameters.enableUserData = true
        parameters.isRecursive = true
        parameters.fields = query.richFields ? [.overview, .genres, .people, .mediaSources] : .MinimumFields
        parameters.limit = query.limit
        parameters.startIndex = pageState.pageOffset

        parameters.includeItemTypes = query.includeItemTypes
        parameters.sortBy = query.sortBy
        parameters.sortOrder = query.sortOrder

        if query.genres.isNotEmpty { parameters.genres = query.genres }
        if query.studioIDs.isNotEmpty { parameters.studioIDs = query.studioIDs }
        if query.personIDs.isNotEmpty { parameters.personIDs = query.personIDs }
        if query.years.isNotEmpty { parameters.years = query.years }
        if let parentID = query.parentID { parameters.parentID = parentID }
        if let minCommunityRating = query.minCommunityRating {
            parameters.minCommunityRating = minCommunityRating
        }

        let filters = query.itemFilters
        if filters.isNotEmpty { parameters.filters = filters }

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)
        let items = response.value.items ?? []

        // Seeded client-side shuffle keeps the shelf reproducible for a given seed
        // without relying on the server's non-reproducible `SortBy=Random`.
        if let seed = query.shuffleSeed {
            return BrunoRNG.shuffled(items, seed: seed)
        }
        return items
    }
}
