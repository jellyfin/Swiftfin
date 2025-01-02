//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class CollectionItemViewModel: ItemViewModel {

    @Published
    private(set) var collectionItems: [BaseItemDto] = []

    override func onRefresh() async throws {
        let collectionItems = try await self.getCollectionItems()

        await MainActor.run {
            self.collectionItems = collectionItems
        }
    }

    private func getCollectionItems() async throws -> [BaseItemDto] {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.parentID = item.id

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
