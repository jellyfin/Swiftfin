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

final class NextUpLibraryViewModel: PagingLibraryViewModel {

    override init() {
        super.init()

        _requestNextPage()
    }

    override func _requestNextPage() {
        Task {

            await MainActor.run {
                self.isLoading = true
            }

            let parameters = Paths.GetNextUpParameters(
                userID: userSession.user.id,
                limit: pageItemSize,
                fields: ItemFields.minimumCases,
                enableUserData: true
            )
            let request = Paths.getNextUp(parameters: parameters)
            let response = try await userSession.client.send(request)

            guard let items = response.value.items, !items.isEmpty else {
                hasNextPage = false
                return
            }

            await MainActor.run {
                self.isLoading = false
                self.items.append(contentsOf: items)
            }
        }
    }

    func markPlayed(item: BaseItemDto) {
        Task {

            let request = Paths.markPlayedItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
            let _ = try await userSession.client.send(request)

            await MainActor.run {
                refresh()
            }
        }
    }
}
