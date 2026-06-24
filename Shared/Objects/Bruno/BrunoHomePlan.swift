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
// `exploreGen` L490, `addMore` L533). `build(seed:snapshot:now:)` is PURE over shelf
// DESCRIPTORS given (seed, snapshot, now) — same inputs ⇒ same home (plan §D). `now` is
// injected (not read from the wall clock) so the date-aware seasonal shelf stays reproducible
// and testable. The stable spine (Continue → Up Next → New Releases → Director → Genre →
// Series → Studio → Eras → Auteurs → Collections) reseeds its *contents* by seed; the explore
// tail is fully seed-derived and grows +2 per scroll page (`appendExplore`).
enum BrunoHomePlan {

    static let minItems = 3
    static let shelfCap = 18

    /// The Romance split (owner request): Romance titles released before this year are their own
    /// "Classic Romance" category, and the regular Romance lens excludes them — so a romcom browse
    /// surfaces modern films, not 1959 ones. The cutoff is the first MODERN year (1985 onward is
    /// "regular Romance"; 1984 and earlier is "Classic Romance").
    static let romanceModernCutoff = 1985

    /// The genre name we split on. Matched case-insensitively against the snapshot's genres so a
    /// library without a literal "Romance" genre simply never produces the Classic Romance shelf.
    static let romanceGenre = "Romance"

    /// All explore generator keys (mirrors the prototype's pool). `year` is intentionally NOT in
    /// the random tail pool: the owner promoted "A Year in Film" into the spine (three distinct
    /// years, placed high — see `build`), so the tail must not surface a fourth, colliding year.
    static let exploreKeys = [
        "acclaimed", "genre", "studio", "decade", "critics", "world", "spotlight", "curated", "seasonal",
    ]

    /// How many distinct "A Year in Film" shelves the spine surfaces (promoted from the tail).
    static let spineYearCount = 3

    // MARK: Spine + initial explore tail

    static func build(seed: UInt32, snapshot: BrunoLibrarySnapshot, now: Date) -> [BrunoShelf] {
        var shelves: [BrunoShelf] = []

        // "A Year in Film" — promoted into the spine. Three distinct years from one seeded
        // permutation (so they never repeat), each shelf seeded independently. Placed high and
        // spread apart below so no two land adjacent (the same-kind adjacency rule would drop one).
        let yearPicks = seededPicks(snapshot.years, seed: seed, salt: 7, count: spineYearCount)
        func yearSpineShelf(_ index: Int) -> BrunoShelf? {
            guard index < yearPicks.count else { return nil }
            return yearShelf(for: yearPicks[index], seed: BrunoRNG.subSeed(seed, 7, UInt32(index), 19))
        }

        // 2. Continue Watching · 3. Up Next · 4. New Releases (stock libraries)
        shelves.append(.init(
            id: "resume",
            lens: "Pick Up Where You Left Off",
            title: "Continue Watching",
            kind: .resume,
            dedupeKey: "resume",
            source: .resume
        ))
        shelves.append(.init(id: "nextup", lens: "Next Episode", title: "Up Next", kind: .nextUp, dedupeKey: "nextUp", source: .nextUp))
        shelves.append(.init(
            id: "recent",
            lens: "Just Added",
            title: "New Releases",
            kind: .recentlyAdded,
            dedupeKey: "recentlyAdded",
            source: .recentlyAdded
        ))

        // 4b. A Year in Film (promoted) — first of the three distinct years, near the top.
        if let yearShelf = yearSpineShelf(0) { shelves.append(yearShelf) }

        // 5. Spotlight on {director} — seeded director group child → its films.
        if let director = seededPick(snapshot.directorBoxSets, seed: seed, salt: 11),
           let id = director.id, let name = director.name
        {
            shelves.append(.init(
                id: "spotlight-\(id)",
                lens: "Director Spotlight",
                title: "Spotlight on \(name)",
                kind: .spotlight,
                dedupeKey: "parent:\(id)",
                source: .query(parentQuery(parentID: id, seed: seed, salt: 11))
            ))
        }

        // 6. {Genre} — "If You Like" a seeded genre. Romance is bounded to modern titles so the
        // pre-1985 classics live only in their own Classic Romance category (owner request).
        if let genre = seededPick(snapshot.genres, seed: seed, salt: 23) {
            shelves.append(.init(
                id: "genre-\(genre)",
                lens: "If You Like",
                title: genre,
                kind: .genre,
                dedupeKey: "genre:\(genre)",
                source: .query(genreQuery(genre: genre, seed: seed, salt: 23, snapshot: snapshot))
            ))
        }

        // 6b. Classic Romance — the pre-1985 romances carved out of the Romance genre so a romcom
        // browse never mixes in 1959 (owner request). A deliberate, branded category, surfaced in
        // the spine. Dropped automatically if the library lacks a Romance genre or enough classics.
        if let classicRomance = classicRomanceShelf(seed: seed, snapshot: snapshot) {
            shelves.append(classicRomance)
        }

        // 7. Series in the Library.
        var seriesQuery = BrunoQuery()
        seriesQuery.includeItemTypes = [.series]
        seriesQuery.shuffleSeed = derive(seed, 31)
        shelves.append(.init(
            id: "series",
            lens: "Television",
            title: "Series in the Library",
            kind: .series,
            dedupeKey: "series",
            source: .query(seriesQuery)
        ))

        // 7b. A Year in Film (promoted) — second distinct year, mid-spine.
        if let yearShelf = yearSpineShelf(1) { shelves.append(yearShelf) }

        // 8. From the {studio} Vault — seeded studio group child.
        if let studio = seededPick(snapshot.studioBoxSets, seed: seed, salt: 41),
           let id = studio.id, let name = studio.name
        {
            shelves.append(.init(
                id: "studio-\(id)",
                lens: "From the Vault",
                title: name,
                kind: .studio,
                dedupeKey: "parent:\(id)",
                source: .query(parentQuery(parentID: id, seed: seed, salt: 41))
            ))
        }

        // 9. Eras — decade tiles (typographic, portrait). 10. Browse by Director. 11. Collections.
        appendItemsShelf(
            &shelves,
            id: "eras",
            lens: "Browse by Decade",
            title: "Eras",
            kind: .eras,
            posterType: .portrait,
            items: snapshot.decadeBoxSets
        )
        appendItemsShelf(
            &shelves,
            id: "auteurs",
            lens: "Auteurs",
            title: "Browse by Director",
            kind: .auteurs,
            posterType: .portrait,
            items: Array(snapshot.directorBoxSets.prefix(14))
        )

        // 10b. A Year in Film (promoted) — third distinct year, before Collections.
        if let yearShelf = yearSpineShelf(2) { shelves.append(yearShelf) }

        appendItemsShelf(
            &shelves,
            id: "collections",
            lens: "Collections",
            title: "Browse the Collection",
            kind: .collections,
            posterType: .portrait,
            items: snapshot.favoriteGroupBoxSets
        )

        // Explore tail: 5 seeded generators, no repeated keys (plan §4).
        var rng = BrunoRNG(seed: seed)
        let keys = rng.shuffled(exploreKeys)
        for index in 0 ..< min(5, keys.count) {
            let slotSeed = BrunoRNG.subSeed(seed, 97, UInt32(index), 13)
            if let shelf = explore(key: keys[index], seed: slotSeed, snapshot: snapshot, now: now) {
                shelves.append(shelf)
            }
        }

        return dedupedAndCapped(shelves)
    }

    // MARK: Infinite-scroll tail (+2 per page)

    /// Two more explore shelves for scroll page `page` (1-based), seed-derived per slot
    /// (mirrors the prototype's `addMore`: `rng(seed*131 + (i+k)*29 + tick)`). Cross-page
    /// content dedupe is the view model's job (via `BrunoShelf.dedupeKey`); here we just bound
    /// the batch to the cap and walk distinct keys.
    static func appendExplore(seed: UInt32, page: Int, alreadyShown: Int, snapshot: BrunoLibrarySnapshot, now: Date) -> [BrunoShelf] {
        let remaining = shelfCap - alreadyShown
        guard remaining > 0 else { return [] }

        var out: [BrunoShelf] = []
        for k in 0 ..< min(2, remaining) {
            let slot = alreadyShown + k
            let key = exploreKeys[(slot + page) % exploreKeys.count]
            let slotSeed = BrunoRNG.subSeed(seed, 131, UInt32(slot) &+ UInt32(page), 29)
            if let shelf = explore(key: key, seed: slotSeed, snapshot: snapshot, now: now) {
                out.append(.init(
                    id: "\(shelf.id)-p\(page)s\(slot)",
                    lens: shelf.lens,
                    title: shelf.title,
                    posterType: shelf.posterType,
                    kind: shelf.kind,
                    dedupeKey: shelf.dedupeKey,
                    source: shelf.source
                ))
            }
        }
        return out
    }

    // MARK: Generators (exploreGen port)

    static func explore(key: String, seed: UInt32, snapshot: BrunoLibrarySnapshot, now: Date) -> BrunoShelf? {
        switch key {
        case "acclaimed":
            var query = BrunoQuery()
            query.minCommunityRating = 8.1
            query.isUnplayed = true
            query.sortBy = [.communityRating]
            query.sortOrder = [.descending]
            query.shuffleSeed = seed
            return .init(
                id: "x-acclaimed",
                lens: "Hidden Gems",
                title: "Acclaimed & Unwatched",
                kind: .acclaimed,
                dedupeKey: "acclaimed",
                source: .query(query)
            )

        case "critics":
            var query = BrunoQuery()
            query.minCommunityRating = 7.5 // floor so the title ("Highest Rated") is honest
            query.sortBy = [.communityRating]
            query.sortOrder = [.descending]
            query.limit = 15
            return .init(
                id: "x-critics",
                lens: "Top of the Library",
                title: "Critics' Highest Rated",
                kind: .critics,
                dedupeKey: "critics",
                source: .query(query)
            )

        case "genre":
            guard let genre = seededPick(snapshot.genres, seed: seed, salt: 7) else { return nil }
            return .init(
                id: "x-genre-\(genre)",
                lens: "If You Like",
                title: genre,
                kind: .genre,
                dedupeKey: "genre:\(genre)",
                // `shuffleSeed = seed` (no salt) preserves the prior explore-tail ordering.
                source: .query(genreQuery(genre: genre, seed: seed, salt: nil, snapshot: snapshot))
            )

        case "studio":
            return boxSetShelf(snapshot.studioBoxSets, idPrefix: "x-studio", lens: "From the Vault", kind: .studio, seed: seed) { name in
                name
            }

        case "decade":
            return boxSetShelf(snapshot.decadeBoxSets, idPrefix: "x-decade", lens: "Lost in Time", kind: .decade, seed: seed) { name in
                "Hidden in the \(name)"
            }

        case "spotlight":
            return boxSetShelf(
                snapshot.directorBoxSets,
                idPrefix: "x-spotlight",
                lens: "Director Spotlight",
                kind: .spotlight,
                seed: seed
            ) { name in "Spotlight on \(name)" }

        case "curated", "world":
            return boxSetShelf(snapshot.curatedBoxSets, idPrefix: "x-curated", lens: "Curated", kind: .curated, seed: seed) { name in name }

        case "seasonal":
            return seasonalShelf(snapshot: snapshot, seed: seed, now: now)

        default:
            return nil
        }
    }

    // MARK: Helpers

    /// An "If You Like {genre}" query. Romance is special-cased to MODERN titles only
    /// (years >= `romanceModernCutoff`) so the pre-1985 classics never bleed into a romcom
    /// browse — they live solely in the Classic Romance category. All other genres are unbounded.
    /// `salt == nil` shuffles with the bare `seed` (preserves the explore tail's existing ordering);
    /// a salt derives a distinct shuffle (the spine).
    private static func genreQuery(genre: String, seed: UInt32, salt: UInt32?, snapshot: BrunoLibrarySnapshot) -> BrunoQuery {
        var query = BrunoQuery()
        query.genres = [genre]
        query.shuffleSeed = salt.map { derive(seed, $0) } ?? seed
        if isRomance(genre) {
            query.years = yearsInRange(snapshot.years, min: romanceModernCutoff, max: nil)
        }
        return query
    }

    /// "Classic Romance": Romance titles released before `romanceModernCutoff`, seed-shuffled.
    /// A deliberate, branded category (lens "Vintage Hearts"). Returns nil when the library has no
    /// Romance genre or too few classics to fill a shelf — the dedupe/cap step drops it then too.
    private static func classicRomanceShelf(seed: UInt32, snapshot: BrunoLibrarySnapshot) -> BrunoShelf? {
        guard let genre = snapshot.genres.first(where: isRomance) else { return nil }
        let classicYears = yearsInRange(snapshot.years, min: nil, max: romanceModernCutoff - 1)
        guard classicYears.count >= 2 else { return nil } // need a real span of vintage years

        var query = BrunoQuery()
        query.genres = [genre]
        query.years = classicYears
        // Stable server sort + seeded client shuffle (the standard Bruno shelf contract): the row
        // stays reproducible for a seed yet rotates day-to-day like every other Bruno shelf.
        query.shuffleSeed = derive(seed, 53)
        return .init(
            id: "classic-romance",
            lens: "Vintage Hearts",
            title: "Classic Romance",
            kind: .classicRomance,
            dedupeKey: "classic-romance",
            source: .query(query)
        )
    }

    private static func isRomance(_ genre: String) -> Bool {
        genre.caseInsensitiveCompare(romanceGenre) == .orderedSame
    }

    /// The snapshot's known years that fall within the inclusive `[min, max]` bound. Jellyfin's
    /// GetItems has no min/max year parameter — only a `Years` inclusion set — so the plan expands
    /// a bound into an explicit list here, keeping `BrunoQueryLibrary` on verified SDK fields.
    static func yearsInRange(_ years: [Int], min: Int?, max: Int?) -> [Int] {
        years.filter { year in
            (min.map { year >= $0 } ?? true) && (max.map { year <= $0 } ?? true)
        }
    }

    /// "A Year in Film": titles released within ±2 years of `year`, seed-shuffled. Promoted into
    /// the spine (three distinct years per home) — see `build`. `dedupeKey` is the year so the
    /// three never collide.
    static func yearShelf(for year: Int, seed: UInt32) -> BrunoShelf {
        var query = BrunoQuery()
        query.years = Array((year - 2) ... (year + 2))
        query.shuffleSeed = seed
        return .init(
            id: "x-year-\(year)",
            lens: "A Year in Film",
            title: "\(year) & Around",
            kind: .year,
            dedupeKey: "year:\(year)",
            source: .query(query)
        )
    }

    /// A query that lists the members of a BoxSet (group child), seed-shuffled. Explicitly scoped
    /// to movies+series so a mixed collection never surfaces folders/extras (red-team L1).
    private static func parentQuery(parentID: String, seed: UInt32, salt: UInt32) -> BrunoQuery {
        var query = BrunoQuery()
        query.parentID = parentID
        query.includeItemTypes = [.movie, .series]
        query.shuffleSeed = derive(seed, salt)
        return query
    }

    /// Build a shelf from a seeded child of a BoxSet group (its members rendered via parentID).
    private static func boxSetShelf(
        _ boxSets: [BaseItemDto],
        idPrefix: String,
        lens: String,
        kind: BrunoShelf.Kind,
        seed: UInt32,
        title: (String) -> String
    ) -> BrunoShelf? {
        guard let pick = seededPick(boxSets, seed: seed, salt: 3),
              let id = pick.id, let name = pick.name else { return nil }
        return .init(
            id: "\(idPrefix)-\(id)",
            lens: lens,
            title: title(name),
            kind: kind,
            dedupeKey: "parent:\(id)",
            source: .query(parentQuery(parentID: id, seed: seed, salt: 3))
        )
    }

    /// Date-aware seasonal pick (Christmas in Dec, Halloween in Oct, 4th of July in early Jul);
    /// otherwise a seeded seasonal collection. `now` is injected to keep `build` reproducible.
    private static func seasonalShelf(snapshot: BrunoLibrarySnapshot, seed: UInt32, now: Date) -> BrunoShelf? {
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
            kind: .seasonal,
            dedupeKey: "parent:\(id)",
            source: .query(parentQuery(parentID: id, seed: seed, salt: 5))
        )
    }

    private static func appendItemsShelf(
        _ shelves: inout [BrunoShelf],
        id: String,
        lens: String,
        title: String,
        kind: BrunoShelf.Kind,
        posterType: PosterDisplayType,
        items: [BaseItemDto]
    ) {
        guard items.count >= minItems else { return }
        shelves.append(.init(id: id, lens: lens, title: title, posterType: posterType, kind: kind, dedupeKey: id, source: .items(items)))
    }

    /// Independent, stable seeded pick (each call site uses a distinct `salt`).
    private static func seededPick<T>(_ array: [T], seed: UInt32, salt: UInt32) -> T? {
        guard array.isNotEmpty else { return nil }
        return BrunoRNG.shuffled(array, seed: derive(seed, salt)).first
    }

    /// The first `count` DISTINCT elements of one seeded shuffle — distinct because they're the
    /// front of a single permutation (used for the spine's three different "A Year in Film" years).
    private static func seededPicks<T>(_ array: [T], seed: UInt32, salt: UInt32, count: Int) -> [T] {
        Array(BrunoRNG.shuffled(array, seed: derive(seed, salt)).prefix(count))
    }

    private static func derive(_ seed: UInt32, _ salt: UInt32) -> UInt32 {
        seed &+ salt &* 2_654_435_761
    }

    /// Drop adjacent shelves of the same kind, drop shelves whose content was already shown,
    /// drop empty `.items` shelves, cap the count.
    private static func dedupedAndCapped(_ shelves: [BrunoShelf]) -> [BrunoShelf] {
        var out: [BrunoShelf] = []
        var seenIDs = Set<String>()
        var seenContent = Set<String>()
        for shelf in shelves {
            if seenIDs.contains(shelf.id) { continue }
            if seenContent.contains(shelf.dedupeKey) { continue }
            if case let .items(items) = shelf.source, items.count < minItems { continue }
            if let last = out.last, last.kind == shelf.kind { continue } // no two adjacent same kind
            out.append(shelf)
            seenIDs.insert(shelf.id)
            seenContent.insert(shelf.dedupeKey)
            if out.count >= shelfCap { break }
        }
        return out
    }
}
