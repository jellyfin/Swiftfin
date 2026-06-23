//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// MARK: - BrunoHomePlan

//
// The "never the same twice" engine, ported from the prototype (`buildBase` L503,
// `exploreGen` L490, `addMore` L533). `build(seed:snapshot:)` is PURE over shelf
// DESCRIPTORS given (seed, snapshot) — same seed ⇒ same home (plan §D). The stable spine
// (Continue → Up Next → New Releases → Director → Genre → Series → Studio → Eras → Auteurs
// → Collections) reseeds its *contents* by seed; the explore tail is fully seed-derived and
// grows +2 per scroll page (`appendExplore`).
enum BrunoHomePlan {

    static let minItems = 3
    static let shelfCap = 18

    /// All explore generator keys (mirrors the prototype's pool).
    static let exploreKeys = [
        "acclaimed", "year", "genre", "studio", "decade", "critics", "world", "spotlight", "curated", "seasonal",
    ]

    // MARK: Spine + initial explore tail

    static func build(seed: UInt32, snapshot: BrunoLibrarySnapshot) -> [BrunoShelf] {
        var shelves: [BrunoShelf] = []

        // 2. Continue Watching · 3. Up Next · 4. New Releases (stock libraries)
        shelves.append(.init(id: "resume", lens: "Pick Up Where You Left Off", title: "Continue Watching", source: .resume))
        shelves.append(.init(id: "nextup", lens: "Next Episode", title: "Up Next", source: .nextUp))
        shelves.append(.init(id: "recent", lens: "Just Added", title: "New Releases", source: .recentlyAdded))

        // 5. Spotlight on {director} — seeded director group child → its films.
        if let director = seededPick(snapshot.directorBoxSets, seed: seed, salt: 11),
           let id = director.id, let name = director.name
        {
            shelves.append(.init(
                id: "spotlight-\(id)",
                lens: "Director Spotlight",
                title: "Spotlight on \(name)",
                source: .query(parentQuery(parentID: id, seed: seed, salt: 11))
            ))
        }

        // 6. {Genre} — "If You Like" a seeded genre.
        if let genre = seededPick(snapshot.genres, seed: seed, salt: 23) {
            var query = BrunoQuery()
            query.genres = [genre]
            query.shuffleSeed = derive(seed, 23)
            shelves.append(.init(id: "genre-\(genre)", lens: "If You Like", title: genre, source: .query(query)))
        }

        // 7. Series in the Library.
        var seriesQuery = BrunoQuery()
        seriesQuery.includeItemTypes = [.series]
        seriesQuery.shuffleSeed = derive(seed, 31)
        shelves.append(.init(id: "series", lens: "Television", title: "Series in the Library", source: .query(seriesQuery)))

        // 8. From the {studio} Vault — seeded studio group child.
        if let studio = seededPick(snapshot.studioBoxSets, seed: seed, salt: 41),
           let id = studio.id, let name = studio.name
        {
            shelves.append(.init(
                id: "studio-\(id)",
                lens: "From the Vault",
                title: name,
                source: .query(parentQuery(parentID: id, seed: seed, salt: 41))
            ))
        }

        // 9. Eras — decade tiles (typographic, portrait). 10. Browse by Director. 11. Collections.
        appendItemsShelf(
            &shelves,
            id: "eras",
            lens: "Browse by Decade",
            title: "Eras",
            posterType: .portrait,
            items: snapshot.decadeBoxSets
        )
        appendItemsShelf(
            &shelves,
            id: "auteurs",
            lens: "Auteurs",
            title: "Browse by Director",
            posterType: .portrait,
            items: Array(snapshot.directorBoxSets.prefix(14))
        )
        appendItemsShelf(
            &shelves,
            id: "collections",
            lens: "Collections",
            title: "Browse the Collection",
            posterType: .portrait,
            items: snapshot.favoriteGroupBoxSets
        )

        // Explore tail: 5 seeded generators, no repeated keys (plan §4).
        var rng = BrunoRNG(seed: seed)
        let keys = rng.shuffled(exploreKeys)
        for index in 0 ..< min(5, keys.count) {
            let slotSeed = BrunoRNG.subSeed(seed, 97, UInt32(index), 13)
            if let shelf = explore(key: keys[index], seed: slotSeed, snapshot: snapshot) {
                shelves.append(shelf)
            }
        }

        return dedupedAndCapped(shelves)
    }

    // MARK: Infinite-scroll tail (+2 per page)

    /// Two more explore shelves for scroll page `page` (1-based), seed-derived per slot
    /// (mirrors the prototype's `addMore`: `rng(seed*131 + (i+k)*29 + tick)`).
    static func appendExplore(seed: UInt32, page: Int, alreadyShown: Int, snapshot: BrunoLibrarySnapshot) -> [BrunoShelf] {
        guard alreadyShown < shelfCap else { return [] }
        var out: [BrunoShelf] = []
        for k in 0 ..< 2 {
            let slot = alreadyShown + k
            let key = exploreKeys[(slot &* 1 + page) % exploreKeys.count]
            let slotSeed = BrunoRNG.subSeed(seed, 131, UInt32(slot) &+ UInt32(page), 29)
            if let shelf = explore(key: key, seed: slotSeed, snapshot: snapshot) {
                out.append(.init(
                    id: "\(shelf.id)-p\(page)s\(slot)",
                    lens: shelf.lens,
                    title: shelf.title,
                    posterType: shelf.posterType,
                    source: shelf.source
                ))
            }
        }
        return out
    }

    // MARK: Generators (exploreGen port)

    static func explore(key: String, seed: UInt32, snapshot: BrunoLibrarySnapshot) -> BrunoShelf? {
        switch key {
        case "acclaimed":
            var query = BrunoQuery()
            query.minCommunityRating = 8.1
            query.isUnplayed = true
            query.sortBy = [.communityRating]
            query.sortOrder = [.descending]
            query.shuffleSeed = seed
            return .init(id: "x-acclaimed", lens: "Hidden Gems", title: "Acclaimed & Unwatched", source: .query(query))

        case "critics":
            var query = BrunoQuery()
            query.sortBy = [.communityRating]
            query.sortOrder = [.descending]
            query.limit = 15
            return .init(id: "x-critics", lens: "Top of the Library", title: "Critics' Highest Rated", source: .query(query))

        case "year":
            guard let year = seededPick(snapshot.years, seed: seed, salt: 7) else { return nil }
            var query = BrunoQuery()
            query.years = Array((year - 2) ... (year + 2))
            query.shuffleSeed = seed
            return .init(id: "x-year-\(year)", lens: "A Year in Film", title: "\(year) & Around", source: .query(query))

        case "genre":
            guard let genre = seededPick(snapshot.genres, seed: seed, salt: 7) else { return nil }
            var query = BrunoQuery()
            query.genres = [genre]
            query.shuffleSeed = seed
            return .init(id: "x-genre-\(genre)", lens: "If You Like", title: genre, source: .query(query))

        case "studio":
            return boxSetShelf(snapshot.studioBoxSets, idPrefix: "x-studio", lens: "From the Vault", seed: seed) { name in name }

        case "decade":
            return boxSetShelf(snapshot.decadeBoxSets, idPrefix: "x-decade", lens: "Lost in Time", seed: seed) { name in
                "Hidden in the \(name)"
            }

        case "spotlight":
            return boxSetShelf(snapshot.directorBoxSets, idPrefix: "x-spotlight", lens: "Director Spotlight", seed: seed) { name in
                "Spotlight on \(name)"
            }

        case "curated", "world":
            return boxSetShelf(snapshot.curatedBoxSets, idPrefix: "x-curated", lens: "Curated", seed: seed) { name in name }

        case "seasonal":
            return seasonalShelf(snapshot: snapshot, seed: seed)

        default:
            return nil
        }
    }

    // MARK: Helpers

    /// A query that lists the members of a BoxSet (group child), seed-shuffled.
    private static func parentQuery(parentID: String, seed: UInt32, salt: UInt32) -> BrunoQuery {
        var query = BrunoQuery()
        query.parentID = parentID
        query.includeItemTypes = []
        query.shuffleSeed = derive(seed, salt)
        return query
    }

    /// Build a shelf from a seeded child of a BoxSet group (its members rendered via parentID).
    private static func boxSetShelf(
        _ boxSets: [BaseItemDto],
        idPrefix: String,
        lens: String,
        seed: UInt32,
        title: (String) -> String
    ) -> BrunoShelf? {
        guard let pick = seededPick(boxSets, seed: seed, salt: 3),
              let id = pick.id, let name = pick.name else { return nil }
        return .init(
            id: "\(idPrefix)-\(id)",
            lens: lens,
            title: title(name),
            source: .query(parentQuery(parentID: id, seed: seed, salt: 3))
        )
    }

    /// Date-aware seasonal pick (Christmas in Dec, Halloween in Oct, 4th of July in early Jul);
    /// otherwise a seeded seasonal collection.
    private static func seasonalShelf(snapshot: BrunoLibrarySnapshot, seed: UInt32, now: Date = Date()) -> BrunoShelf? {
        let month = Calendar.current.component(.month, from: now)
        let keyword: String? = switch month {
        case 12: "christmas"
        case 10: "halloween"
        case 7: "july"
        default: nil
        }

        let chosen: BaseItemDto? = {
            if let keyword,
               let match = snapshot.seasonalBoxSets.first(where: { ($0.name ?? "").lowercased().contains(keyword) })
            {
                return match
            }
            return seededPick(snapshot.seasonalBoxSets, seed: seed, salt: 5)
        }()

        guard let chosen, let id = chosen.id, let name = chosen.name else { return nil }
        return .init(
            id: "x-seasonal-\(id)",
            lens: "In Season",
            title: "\(name) Picks",
            source: .query(parentQuery(parentID: id, seed: seed, salt: 5))
        )
    }

    private static func appendItemsShelf(
        _ shelves: inout [BrunoShelf],
        id: String,
        lens: String,
        title: String,
        posterType: PosterDisplayType,
        items: [BaseItemDto]
    ) {
        guard items.count >= minItems else { return }
        shelves.append(.init(id: id, lens: lens, title: title, posterType: posterType, source: .items(items)))
    }

    /// Independent, stable seeded pick (each call site uses a distinct `salt`).
    private static func seededPick<T>(_ array: [T], seed: UInt32, salt: UInt32) -> T? {
        guard array.isNotEmpty else { return nil }
        return BrunoRNG.shuffled(array, seed: derive(seed, salt)).first
    }

    private static func derive(_ seed: UInt32, _ salt: UInt32) -> UInt32 {
        seed &+ salt &* 2_654_435_761
    }

    /// Drop adjacent shelves of the same kind, drop empty `.items` shelves, cap the count.
    private static func dedupedAndCapped(_ shelves: [BrunoShelf]) -> [BrunoShelf] {
        var out: [BrunoShelf] = []
        var seenIDs = Set<String>()
        for shelf in shelves {
            if seenIDs.contains(shelf.id) { continue }
            if case let .items(items) = shelf.source, items.count < minItems { continue }
            if let last = out.last, last.kindTag == shelf.kindTag, shelf.kindTag.hasPrefix("query") {
                continue // no two adjacent same-kind explore/query shelves
            }
            out.append(shelf)
            seenIDs.insert(shelf.id)
            if out.count >= shelfCap { break }
        }
        return out
    }
}
