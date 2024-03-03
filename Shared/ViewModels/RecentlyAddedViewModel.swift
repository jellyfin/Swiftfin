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

final class RecentlyAddedLibraryViewModel: PagingLibraryViewModel<BaseItemDto> {

    override func get(page: Int) async throws -> [BaseItemDto] {

        let parameters = parameters(for: page)
        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    private func parameters(for page: Int) -> Paths.GetItemsByUserIDParameters {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.limit = DefaultPageSize
        parameters.startIndex = page
        parameters.isRecursive = true
        parameters.sortOrder = [.descending]
        parameters.fields = ItemFields.MinimumFields
        parameters.includeItemTypes = [.movie, .series]
        parameters.sortBy = [ItemSortBy.dateAdded.rawValue]
        parameters.enableUserData = true

        return parameters
    }
}
