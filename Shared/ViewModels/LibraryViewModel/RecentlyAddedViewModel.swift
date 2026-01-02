//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

// TODO: verify this properly returns pages of items in correct date-added order
//       *when* new episodes are added to a series?
final class RecentlyAddedLibraryViewModel: PagingLibraryViewModel<BaseItemDto> {

    // Necessary because this is paginated and also used on home view
    init(customPageSize: Int? = nil) {

        // Why doesn't `super.init(title:id:pageSize)` init work?
        if let customPageSize {
            super.init(parent: TitledLibraryParent(displayTitle: L10n.recentlyAdded, id: "recentlyAdded"), pageSize: customPageSize)
        } else {
            super.init(parent: TitledLibraryParent(displayTitle: L10n.recentlyAdded, id: "recentlyAdded"))
        }
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
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.movie, .series]
        parameters.isRecursive = true
        parameters.limit = pageSize
        parameters.sortBy = [ItemSortBy.dateCreated.rawValue]
        parameters.sortOrder = [.descending]
        parameters.startIndex = page

        // Necessary to get an actual "next page" with this endpoint.
        // Could be a performance issue for lots of items, but there's
        // nothing we can do about it.
        parameters.excludeItemIDs = elements.compactMap(\.id)

        return parameters
    }
}
