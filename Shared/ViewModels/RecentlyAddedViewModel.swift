//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
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
        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            startIndex: currentPage * pageItemSize,
            limit: pageItemSize,
            recursive: true,
            sortOrder: [.descending],
            fields: ItemFields.allCases,
            includeItemTypes: [.movie, .series],
            sortBy: [SortBy.dateAdded.rawValue],
            enableUserData: true
        )
        .trackActivity(loading)
        .sink { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        } receiveValue: { [weak self] response in
            guard let items = response.items, !items.isEmpty else {
                self?.hasNextPage = false
                return
            }

            self?.items.append(contentsOf: items)
        }
        .store(in: &cancellables)
    }
}
