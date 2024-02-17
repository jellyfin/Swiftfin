//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// While this is similar to `LibraryViewModel`, a bit more handling
// is required to handle `collectionFolder` collectionType items,
// which is changed to a `folder` collectionType for view-handling
// final class FolderViewModel: LibraryViewModel {
//
//    override func get(page: Int) async throws -> [BaseItemDto] {
//        let parameters = getItemParameters(for: page)
//        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
//        let response = try await userSession.client.send(request)
//
//        var validItems = (response.value.items ?? []).compactMap { item in
//
//            if item.collectionType == "collectionFolder" {
//                var t = item
//                t.collectionType = "folder"
//                return t
//            }
//
//            return item
//        }
//
//        return validItems
//    }
//
//    override func getItemParameters(for page: Int) -> Paths.GetItemsByUserIDParameters {
//
//        let filters = filterViewModel.currentFilters
//
//        var parameters = Paths.GetItemsByUserIDParameters()
//        parameters.parentID = parent?.id
//        parameters.fields = ItemFields.minimumCases
//        parameters.includeItemTypes = [.movie, .series, .boxSet, .folder, .collectionFolder]
//
//        parameters.limit = Self.DefaultPageSize
//        parameters.startIndex = page * Self.DefaultPageSize
//        parameters.sortOrder = filters.sortOrder.map { SortOrder(rawValue: $0.filterName) ?? .ascending }
//        parameters.sortBy = filters.sortBy.map(\.filterName).prepending("IsFolder")
//
//        return parameters
//    }
// }
