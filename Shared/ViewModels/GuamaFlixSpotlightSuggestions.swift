//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI

enum GuamaFlixSpotlightSuggestions {

    private static let excludedLibraryNames: Set<String> = [
        "discover",
        "request",
        "requests",
    ]

    private static let spotlightLibraryNames: Set<String> = [
        "movies",
        "tv shows",
        "tvshows",
    ]

    private static func normalizedName(of library: BaseItemDto) -> String {
        library.displayTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }

    static func isExcludedLibrary(_ library: BaseItemDto) -> Bool {
        excludedLibraryNames.contains(normalizedName(of: library))
    }

    static func isEligibleSpotlightLibrary(_ library: BaseItemDto) -> Bool {
        guard let collectionType = library.collectionType,
              [.movies, .tvshows].contains(collectionType) else { return false }

        return spotlightLibraryNames.contains(normalizedName(of: library))
    }

    @MainActor
    static func sampledItems(limit: Int = 10) async -> [BaseItemDto] {
        guard let session = Container.shared.currentUserSession() else {
            return []
        }

        let libraries = await spotlightLibraries(session: session)
        guard libraries.isNotEmpty else { return [] }

        let suggestedItems = await suggestedItems(
            session: session,
            libraries: libraries,
            limit: limit * 2
        )

        if suggestedItems.count >= limit {
            return Array(suggestedItems.prefix(limit))
        }

        let recentlyAddedItems = await recentlyAddedItems(
            session: session,
            libraries: libraries,
            limit: limit * 2
        )
        var seenItemIDs = Set<String>()
        let mergedItems = (suggestedItems + recentlyAddedItems).filter { item in
            guard let id = item.id else { return true }
            return seenItemIDs.insert(id).inserted
        }

        return Array(mergedItems.prefix(limit))
    }

    private static func spotlightLibraries(session: UserSession) async -> [BaseItemDto] {
        var parameters = Paths.GetUserViewsParameters()
        parameters.userID = session.user.id

        do {
            let response = try await session.client.send(Paths.getUserViews(parameters: parameters))
            return (response.value.items ?? []).filter(isEligibleSpotlightLibrary)
        } catch {
            return []
        }
    }

    private static func suggestedItems(
        session: UserSession,
        libraries: [BaseItemDto],
        limit: Int
    ) async -> [BaseItemDto] {
        var libraryItems: [[BaseItemDto]] = []

        for library in libraries {
            guard let libraryID = library.id else { continue }

            var parameters = Paths.GetItemsParameters()
            parameters.enableUserData = true
            parameters.fields = .MinimumFields
            parameters.includeItemTypes = [.movie, .series]
            parameters.isRecursive = true
            parameters.limit = limit
            parameters.parentID = libraryID
            parameters.sortBy = [ItemSortBy.random]

            do {
                let response = try await session.client.send(Paths.getItems(parameters: parameters))
                libraryItems.append((response.value.items ?? []).filter(hasHeroArtwork))
            } catch {
                continue
            }
        }

        let largestLibraryCount = libraryItems.map(\.count).max() ?? 0
        return (0 ..< largestLibraryCount).flatMap { index in
            libraryItems.compactMap { $0[safe: index] }
        }
    }

    private static func recentlyAddedItems(
        session: UserSession,
        libraries: [BaseItemDto],
        limit: Int
    ) async -> [BaseItemDto] {
        var libraryItems: [[BaseItemDto]] = []

        for library in libraries {
            guard let libraryID = library.id else { continue }

            var parameters = Paths.GetItemsParameters()
            parameters.enableUserData = true
            parameters.fields = .MinimumFields
            parameters.includeItemTypes = [.movie, .series]
            parameters.isRecursive = true
            parameters.limit = limit
            parameters.parentID = libraryID
            parameters.sortBy = [ItemSortBy.dateCreated]
            parameters.sortOrder = [.descending]

            do {
                let response = try await session.client.send(Paths.getItems(parameters: parameters))
                libraryItems.append((response.value.items ?? []).filter(hasHeroArtwork))
            } catch {
                continue
            }
        }

        let largestLibraryCount = libraryItems.map(\.count).max() ?? 0
        return (0 ..< largestLibraryCount).flatMap { index in
            libraryItems.compactMap { $0[safe: index] }
        }
    }

    private static func hasHeroArtwork(_ item: BaseItemDto) -> Bool {
        item.backdropImageTags?.isNotEmpty == true ||
            item.imageTags?[ImageType.thumb.rawValue]?.isEmpty == false
    }
}
