//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

// TODO: verify this properly returns pages of items in correct date-added order
//       *when* new episodes are added to a series?
final class RecentlyAddedLibraryViewModel: PagingLibraryViewModel<BaseItemDto> {

    private let excludesHomeDiscoveryLibraries: Bool

    // Necessary because this is paginated and also used on home view
    init(
        customPageSize: Int? = nil,
        excludingHomeDiscoveryLibraries: Bool = false
    ) {
        self.excludesHomeDiscoveryLibraries = excludingHomeDiscoveryLibraries

        // Why doesn't `super.init(title:id:pageSize)` init work?
        if let customPageSize {
            super.init(parent: TitledLibraryParent(displayTitle: L10n.recentlyAdded, id: "recentlyAdded"), pageSize: customPageSize)
        } else {
            super.init(parent: TitledLibraryParent(displayTitle: L10n.recentlyAdded, id: "recentlyAdded"))
        }
    }

    override func get(page: Int) async throws -> [BaseItemDto] {

        if excludesHomeDiscoveryLibraries {
            return try await getHomeItems(page: page)
        }

        let parameters = try parameters(for: page, user: authenticatedUser)
        let request = Paths.getItems(parameters: parameters)
        let response = try await send(request)

        return response.value.items ?? []
    }

    private func getHomeItems(page: Int) async throws -> [BaseItemDto] {
        let user = try authenticatedUser
        let userViewsParameters = Paths.GetUserViewsParameters(userID: user.id)
        let userViewsResponse = try await send(Paths.getUserViews(parameters: userViewsParameters))
        let libraries = (userViewsResponse.value.items ?? [])
            .filter(GuamaFlixSpotlightSuggestions.isEligibleSpotlightLibrary)

        var libraryItems: [BaseItemDto] = []

        for library in libraries {
            guard let libraryID = library.id else { continue }

            var parameters = parameters(for: page, user: user)
            parameters.parentID = libraryID
            parameters.startIndex = page * pageSize

            let response = try await send(Paths.getItems(parameters: parameters))
            libraryItems.append(contentsOf: response.value.items ?? [])
        }

        var seenItemIDs = Set<String>()
        let sortedItems = libraryItems
            .sorted { ($0.dateCreated ?? .distantPast) > ($1.dateCreated ?? .distantPast) }
            .filter { item in
                guard let id = item.id else { return true }
                return seenItemIDs.insert(id).inserted
            }

        return Array(sortedItems.prefix(pageSize))
    }

    private func parameters(for page: Int, user: UserState) -> Paths.GetItemsParameters {

        var parameters = Paths.GetItemsParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.movie, .series]
        parameters.isRecursive = true
        parameters.limit = pageSize
        parameters.sortBy = [ItemSortBy.dateCreated]
        parameters.sortOrder = [.descending]
        parameters.startIndex = page

        // Necessary to get an actual "next page" with this endpoint.
        // Could be a performance issue for lots of items, but there's
        // nothing we can do about it.
        parameters.excludeItemIDs = elements.compactMap(\.id)

        if user.data.configuration?.isHidePlayedInLatest == true {
            parameters.isPlayed = false
        }

        return parameters
    }
}
