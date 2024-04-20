//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

final class LatestInLibraryViewModel: PagingLibraryViewModel<BaseItemDto>, Identifiable {

    override func get(page: Int) async throws -> [BaseItemDto] {

        let parameters = parameters(for: page)
        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    private func parameters(for page: Int) -> Paths.GetItemsByUserIDParameters {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.parentID = parent?.id
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.movie, .series]
        parameters.isRecursive = true
        parameters.limit = pageSize
        parameters.sortBy = [ItemSortBy.premiereDate.rawValue]
        parameters.sortOrder = [.descending]
        parameters.startIndex = page

        // Necessary to get an actual "next page" with this endpoint.
        // Could be a performance issue for lots of items, but there's
        // nothing we can do about it.
        parameters.excludeItemIDs = elements.compactMap(\.id)

        return parameters
    }
}
