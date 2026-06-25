//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// MARK: - BrunoLibrarySnapshot

//
// Fetched ONCE (async) when the home refreshes; after that `BrunoHomePlan.build` is pure
// over it (plan §D/§E). The owner's library is curated as 7 favorited "group" BoxSets
// (Directors, Decades, Studios, Genres, Curated, Seasonal, New Releases) whose children are
// the real sub-collections. We never hardcode IDs — everything is derived here from the
// live library (validated in BRUNO_NOTES.md §Live library snapshot).
//
// Codable + Sendable so it can be persisted to disk (instant relaunch — see BrunoHomeCache) and
// crossed to a detached encode/decode task without `nonisolated(unsafe)`. All stored members are
// already Sendable/Codable (`BaseItemDto` is both).
struct BrunoLibrarySnapshot: Codable {

    /// The favorited top-level group BoxSets (the spec's 7 groups), in server order.
    let favoriteGroupBoxSets: [BaseItemDto]
    /// For each group BoxSet name → its child items (sub-BoxSets for most groups).
    let childrenByGroupName: [String: [BaseItemDto]]
    /// Distinct genre names present in the library.
    let genres: [String]
    /// Distinct production years present (for the "year" explore generator).
    let years: [Int]

    static var empty: BrunoLibrarySnapshot {
        .init(favoriteGroupBoxSets: [], childrenByGroupName: [:], genres: [], years: [])
    }

    // Case-insensitive group lookups (group names are owner-authored).
    private func group(_ name: String) -> [BaseItemDto] {
        if let exact = childrenByGroupName[name] { return exact }
        let lower = name.lowercased()
        for (key, value) in childrenByGroupName where key.lowercased() == lower {
            return value
        }
        return []
    }

    var directorBoxSets: [BaseItemDto] {
        group("Directors")
    }

    var decadeBoxSets: [BaseItemDto] {
        group("Decades")
    }

    var studioBoxSets: [BaseItemDto] {
        group("Studios")
    }

    var genreBoxSets: [BaseItemDto] {
        group("Genres")
    }

    var curatedBoxSets: [BaseItemDto] {
        group("Curated")
    }

    var seasonalBoxSets: [BaseItemDto] {
        group("Seasonal")
    }

    var isEmpty: Bool {
        favoriteGroupBoxSets.isEmpty && genres.isEmpty
    }
}

extension BrunoLibrarySnapshot {

    /// Loads the snapshot from the live library. Best-effort: any sub-fetch that fails or
    /// returns nothing simply yields an empty slice, and dependent shelves are dropped later.
    static func load(client: JellyfinClient, userID: String) async -> BrunoLibrarySnapshot {
        async let groupsTask = fetchGroupBoxSets(client: client, userID: userID)
        async let genresTask = fetchGenres(client: client, userID: userID)
        async let yearsTask = fetchYears(client: client, userID: userID)

        let groups = await groupsTask

        // Fetch each group's children concurrently.
        var childrenByName: [String: [BaseItemDto]] = [:]
        await withTaskGroup(of: (String, [BaseItemDto]).self) { taskGroup in
            for boxSet in groups {
                guard let id = boxSet.id, let name = boxSet.name else { continue }
                taskGroup.addTask {
                    let children = await fetchChildren(client: client, userID: userID, parentID: id)
                    return (name, children)
                }
            }
            for await (name, children) in taskGroup {
                childrenByName[name] = children
            }
        }

        return await BrunoLibrarySnapshot(
            favoriteGroupBoxSets: groups,
            childrenByGroupName: childrenByName,
            genres: genresTask,
            years: yearsTask
        )
    }

    private static func fetchGroupBoxSets(client: JellyfinClient, userID: String) async -> [BaseItemDto] {
        var parameters = Paths.GetItemsParameters()
        parameters.userID = userID
        parameters.isRecursive = true
        parameters.includeItemTypes = [.boxSet]
        parameters.filters = [.isFavorite]
        parameters.fields = .MinimumFields
        parameters.limit = 50
        return await send(client: client, parameters: parameters)
    }

    private static func fetchChildren(client: JellyfinClient, userID: String, parentID: String) async -> [BaseItemDto] {
        var parameters = Paths.GetItemsParameters()
        parameters.userID = userID
        parameters.parentID = parentID
        parameters.fields = .MinimumFields
        parameters.enableUserData = true
        parameters.limit = 200
        return await send(client: client, parameters: parameters)
    }

    private static func fetchGenres(client: JellyfinClient, userID: String) async -> [String] {
        var parameters = Paths.GetGenresParameters()
        parameters.userID = userID
        parameters.includeItemTypes = [.movie, .series]
        parameters.limit = 60
        do {
            let response = try await client.send(Paths.getGenres(parameters: parameters))
            return (response.value.items ?? []).compactMap(\.name)
        } catch {
            return []
        }
    }

    private static func fetchYears(client: JellyfinClient, userID: String) async -> [Int] {
        var parameters = Paths.GetItemsParameters()
        parameters.userID = userID
        parameters.isRecursive = true
        parameters.includeItemTypes = [.movie]
        parameters.sortBy = [.productionYear]
        parameters.sortOrder = [.descending]
        parameters.fields = .MinimumFields
        parameters.limit = 400
        let items = await send(client: client, parameters: parameters)
        let years = Set(items.compactMap(\.productionYear)).filter { $0 > 1900 }
        return years.sorted()
    }

    private static func send(client: JellyfinClient, parameters: Paths.GetItemsParameters) async -> [BaseItemDto] {
        do {
            let response = try await client.send(Paths.getItems(parameters: parameters))
            return response.value.items ?? []
        } catch {
            return []
        }
    }
}

// MARK: - Shared cache

extension BrunoLibrarySnapshot {

    /// In-memory cache so navigating Home -> Collections reuses the snapshot Home just loaded
    /// instead of refetching the whole library each time (the "slow loads between pages"). Short
    /// TTL; keyed by userID so a user switch never serves stale data; explicit refreshes bypass it.
    private actor Cache {
        private var snapshot: BrunoLibrarySnapshot?
        private var userID: String?
        private var loadedAt: Date?

        func value(userID: String, maxAge: TimeInterval) -> BrunoLibrarySnapshot? {
            guard self.userID == userID,
                  let snapshot, let loadedAt,
                  !snapshot.isEmpty,
                  Date().timeIntervalSince(loadedAt) < maxAge
            else { return nil }
            return snapshot
        }

        func store(_ snapshot: BrunoLibrarySnapshot, userID: String) {
            guard !snapshot.isEmpty else { return }
            self.snapshot = snapshot
            self.userID = userID
            self.loadedAt = Date()
        }
    }

    private static let cache = Cache()

    /// Like `load`, but reuses a recent in-memory snapshot for the same user (default 5 min). Pass
    /// `forceReload: true` for explicit refreshes (still stores the fresh result so peers can reuse).
    static func loadShared(
        client: JellyfinClient,
        userID: String,
        maxAge: TimeInterval = 300,
        forceReload: Bool = false
    ) async -> BrunoLibrarySnapshot {
        if !forceReload, let cached = await cache.value(userID: userID, maxAge: maxAge) {
            return cached
        }
        let fresh = await load(client: client, userID: userID)
        await cache.store(fresh, userID: userID)
        return fresh
    }

    /// Seed the in-memory cache with a snapshot we already have (e.g. one hydrated from disk on
    /// launch), so Collections / drill-ins reuse it this session instead of refetching.
    static func seedCache(_ snapshot: BrunoLibrarySnapshot, userID: String) async {
        await cache.store(snapshot, userID: userID)
    }
}
