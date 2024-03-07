//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

// TODO: verify this properly returns pages of items in correct date-added order
final class RecentlyAddedLibraryViewModel: PagingLibraryViewModel<BaseItemDto> {

    init() {
        super.init(parent: TitledLibraryParent(displayTitle: L10n.recentlyAdded))
    }

    override func get(page: Int) async throws -> [BaseItemDto] {

        let parameters = parameters(for: page)
        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    private func parameters(for page: Int) -> Paths.GetItemsByUserIDParameters {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = ItemFields.MinimumFields
        parameters.includeItemTypes = [.movie, .series]
        parameters.isRecursive = true
        parameters.limit = DefaultPageSize
        parameters.sortBy = [ItemSortBy.dateAdded.rawValue]
        parameters.sortOrder = [.descending]
        parameters.startIndex = page

        // Ncessary to get an actual "next page" with this endpoint.
        // Could be a performance issue for lots of items, but there's
        // nothing we can do about it.
        parameters.excludeItemIDs = items.compactMap(\.id)

        return parameters
    }
}
