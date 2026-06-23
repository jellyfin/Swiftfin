//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// MARK: - BrunoShelf

//
// One horizontal row on the Bruno home screen. This is a DESCRIPTOR — `BrunoHomePlan.build`
// produces a deterministic ordered list of these from a seed + snapshot (plan §D: pure over
// descriptors, not over fetched items). `BrunoHomeViewModel` then realises each descriptor
// into something `PosterHStack` can render (a child paging VM, or a pre-resolved item array).
struct BrunoShelf: Identifiable {

    /// The role of a shelf. Used for the "no two adjacent shelves of the same kind" rule —
    /// distinct from `dedupeKey`, which dedupes by *content*. (Without a per-role kind, all
    /// parentID-backed shelves would collapse together and the adjacency rule would wrongly
    /// drop e.g. a Decade row that follows a Studio row.)
    enum Kind: String {
        case resume
        case nextUp
        case recentlyAdded
        case spotlight
        case genre
        case series
        case studio
        case eras
        case auteurs
        case collections
        case acclaimed
        case critics
        case year
        case decade
        case curated
        case seasonal
    }

    enum Source {
        /// Continue Watching — `ResumeItemsLibrary` (movies + episodes).
        case resume
        /// Up Next — `NextUpLibrary`.
        case nextUp
        /// New Releases — `RecentlyAddedLibrary`.
        case recentlyAdded
        /// A computed/curated query backed by `BrunoQueryLibrary` (stable sort + seeded shuffle).
        case query(BrunoQuery)
        /// Pre-resolved items from the snapshot (group tiles, group children) — rendered directly.
        case items([BaseItemDto])
    }

    /// Stable identity across rebuilds with the same seed (drives `ForEach` + dedupe).
    let id: String
    /// Eyebrow / lens label above the title (e.g. "Director Spotlight").
    let lens: String
    let title: String
    let posterType: PosterDisplayType
    let kind: Kind
    /// Content identity (e.g. the BoxSet parentID, genre, or year) so the same collection is
    /// never shown twice — including across infinite-scroll pages.
    let dedupeKey: String
    let source: Source

    init(
        id: String,
        lens: String,
        title: String,
        posterType: PosterDisplayType = .landscape,
        kind: Kind,
        dedupeKey: String,
        source: Source
    ) {
        self.id = id
        self.lens = lens
        self.title = title
        self.posterType = posterType
        self.kind = kind
        self.dedupeKey = dedupeKey
        self.source = source
    }
}
