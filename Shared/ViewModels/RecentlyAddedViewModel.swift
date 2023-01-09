//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class RecentlyAddedLibraryViewModel: PagingLibraryViewModel {

    override init() {
        super.init()

        _requestNextPage()
    }

    override func _requestNextPage() {
        Task {
            let parameters = Paths.GetItemsParameters(
                userID: userSession.user.id,
                startIndex: currentPage * pageItemSize,
                limit: pageItemSize,
                isRecursive: true,
                sortOrder: [.descending],
                fields: ItemFields.allCases,
                includeItemTypes: [.movie, .series],
                sortBy: [SortBy.dateAdded.rawValue],
                enableUserData: true
            )
            let request = Paths.getItems(parameters: parameters)
            let response = try await userSession.client.send(request)

            guard let items = response.value.items, !items.isEmpty else {
                hasNextPage = false
                return
            }

            await MainActor.run {
                self.items.append(contentsOf: items)
            }
        }
    }
}
