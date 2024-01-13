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

final class LatestInLibraryViewModel: PagingLibraryViewModel {

    let parent: LibraryParent

    init(parent: LibraryParent) {
        self.parent = parent

        super.init()

        _requestNextPage()
    }

    override func _requestNextPage() {
        Task {

            await MainActor.run {
                self.isLoading = true
            }

            let parameters = Paths.GetLatestMediaParameters(
                parentID: self.parent.id,
                fields: ItemFields.minimumCases,
                enableUserData: true,
                limit: self.pageItemSize * 3
            )
            let request = Paths.getLatestMedia(userID: userSession.user.id, parameters: parameters)
            let response = try await userSession.client.send(request)

            let items = response.value
            if items.isEmpty {
                hasNextPage = false
                return
            }

            await MainActor.run {
                self.isLoading = false
                self.items.append(contentsOf: items)
            }
        }
    }

    override public func getRandomItemFromLibrary() async throws -> BaseItemDtoQueryResult {
        BaseItemDtoQueryResult(items: items.elements)
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
