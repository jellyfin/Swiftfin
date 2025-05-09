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
import OrderedCollections

final class CollectionItemViewModel: ItemViewModel {

    // MARK: - Published Collection Items

    @Published
    private(set) var collectionItems: OrderedDictionary<BaseItemKind, [BaseItemDto]> = [:]

    // MARK: - On Refresh

    override func onRefresh() async throws {
        let collectionItems = try await self.getCollectionItems()

        await MainActor.run {
            self.collectionItems = collectionItems
        }
    }

    // MARK: - Get Collection Items

    private func getCollectionItems() async throws -> OrderedDictionary<BaseItemKind, [BaseItemDto]> {
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.parentID = item.id

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        let items = response.value.items ?? []

        let groupedItems: OrderedDictionary<BaseItemKind?, [BaseItemDto]> = .init(
            grouping: items,
            by: \.type
        )

        let result = groupedItems.compactKeys()

        return OrderedDictionary(
            uniqueKeysWithValues:
            result.sorted { $0.key.displayTitle < $1.key.displayTitle }
        )
    }
}
