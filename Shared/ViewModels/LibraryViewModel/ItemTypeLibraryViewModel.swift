//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Get
import JellyfinAPI

// TODO: filtering on `itemTypes` should be moved to `ItemFilterCollection`,
//       but there is additional logic based on the parent type, mainly `.folder`.
final class ItemTypeLibraryViewModel: PagingLibraryViewModel<BaseItemDto> {

    let itemTypes: [BaseItemKind]

    // MARK: Initializer

    init(
        itemTypes: [BaseItemKind],
        filters: ItemFilterCollection? = nil
    ) {
        self.itemTypes = itemTypes

        super.init(
            itemTypes: itemTypes,
            filters: filters
        )
    }

    // MARK: Get Page

    override func get(page: Int) async throws -> [BaseItemDto] {

        let parameters = itemParameters(for: page)
        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    // MARK: Item Parameters

    func itemParameters(for page: Int?) -> Paths.GetItemsByUserIDParameters {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = itemTypes
        parameters.isRecursive = true

        // Page size
        if let page {
            parameters.limit = pageSize
            parameters.startIndex = page * pageSize
        }

        // Filters
        if let filterViewModel {
            let filters = filterViewModel.currentFilters
            parameters.filters = filters.traits
            parameters.genres = filters.genres.map(\.value)
            parameters.sortBy = filters.sortBy.map(\.rawValue)
            parameters.sortOrder = filters.sortOrder
            parameters.tags = filters.tags.map(\.value)
            parameters.years = filters.years.compactMap { Int($0.value) }

            if filters.letter.first?.value == "#" {
                parameters.nameLessThan = "A"
            } else {
                parameters.nameStartsWith = filters.letter
                    .map(\.value)
                    .filter { $0 != "#" }
                    .first
            }

            // Random sort won't take into account previous items, so
            // manual exclusion is necessary. This could possibly be
            // a performance issue for loading pages after already loading
            // many items, but there's nothing we can do about that.
            if filters.sortBy.first == ItemSortBy.random {
                parameters.excludeItemIDs = elements.compactMap(\.id)
            }
        }

        return parameters
    }

    // MARK: Get Random Item

    override func getRandomItem() async -> BaseItemDto? {

        var parameters = itemParameters(for: nil)
        parameters.limit = 1
        parameters.sortBy = [ItemSortBy.random.rawValue]

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try? await userSession.client.send(request)

        return response?.value.items?.first
    }
}
