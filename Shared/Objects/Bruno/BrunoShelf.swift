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
    let source: Source

    init(
        id: String,
        lens: String,
        title: String,
        posterType: PosterDisplayType = .landscape,
        source: Source
    ) {
        self.id = id
        self.lens = lens
        self.title = title
        self.posterType = posterType
        self.source = source
    }

    /// A coarse kind used for the "no two adjacent shelves of the same kind" dedupe rule
    /// and for determinism assertions (PRODUCT_SPEC §4).
    var kindTag: String {
        switch source {
        case .resume: "resume"
        case .nextUp: "nextUp"
        case .recentlyAdded: "recentlyAdded"
        case let .items(items): "items(\(items.count))"
        case let .query(query):
            if query.parentID != nil { "query.parent" }
            else if query.genres.isNotEmpty { "query.genre" }
            else if query.studioIDs.isNotEmpty { "query.studio" }
            else if query.personIDs.isNotEmpty { "query.person" }
            else if query.years.isNotEmpty { "query.year" }
            else if query.minCommunityRating != nil { "query.acclaimed" }
            else { "query" }
        }
    }
}
