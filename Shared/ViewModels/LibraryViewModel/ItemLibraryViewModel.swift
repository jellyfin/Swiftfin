//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Get
import JellyfinAPI
import OrderedCollections
import SwiftUI

final class ItemLibraryViewModel: PagingLibraryViewModel<BaseItemDto> {

    // MARK: get

    override func get(page: Int) async throws -> [BaseItemDto] {

        let parameters = itemParameters(for: page)
        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        // 1 - only care to keep collections that hold valid items
        // 2 - if parent is type `folder`, then we are in a folder-view
        //     context so change `collectionFolder` types to `folder`
        //     for better view handling
        let items = (response.value.items ?? [])
            .filter { item in
                if let collectionType = item.collectionType {
                    return ["movies", "tvshows", "mixed", "boxsets"].contains(collectionType)
                }

                return true
            }
            .map { item in
                if parent?.libraryType == .folder, item.type == .collectionFolder {
                    return item.mutating(\.type, with: .folder)
                }

                return item
            }

        return items
    }

    // MARK: item parameters

    func itemParameters(for page: Int?) -> Paths.GetItemsByUserIDParameters {

        var libraryID: String?
        var personIDs: [String]?
        var studioIDs: [String]?
        var includeItemTypes: [BaseItemKind] = [.movie, .series, .boxSet]
        var isRecursive: Bool? = true

        if let libraryType = parent?.libraryType, let id = parent?.id {
            switch libraryType {
            case .collectionFolder:
                libraryID = id
            case .folder, .userView:
                libraryID = id
                isRecursive = nil
                includeItemTypes = [.movie, .series, .boxSet, .folder, .collectionFolder]
            case .person:
                personIDs = [id]
            case .studio:
                studioIDs = [id]
            default: ()
            }
        }

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = includeItemTypes
        parameters.isRecursive = isRecursive
        parameters.parentID = libraryID
        parameters.personIDs = personIDs
        parameters.studioIDs = studioIDs

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

    // MARK: getRandomItem

    override func getRandomItem() async -> BaseItemDto? {

        var parameters = itemParameters(for: nil)
        parameters.limit = 1
        parameters.sortBy = [ItemSortBy.random.rawValue]

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try? await userSession.client.send(request)

        return response?.value.items?.first
    }
}
