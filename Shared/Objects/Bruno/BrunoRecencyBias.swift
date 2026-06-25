//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// MARK: - BrunoRecencyBias

//
// The single source of truth for Bruno's "modern bias" (owner request). The genre browse shelves
// were drowning in pre-80s classics (every "If You Like {genre}" row was 1940s–60s), so the genre
// ROWS are restricted to modern titles; the classics aren't deleted — they sink to the bottom of
// each genre's full "Show all" grid (newest-first sort) and live in the Classic carve-outs / Eras.
enum BrunoRecencyBias {

    /// First "modern" production year. A title released in this year or later is eligible for the
    /// "If You Like {genre}" rows; earlier films are the bottom of the barrel (full grid only).
    /// 1985 matches the existing Classic Romance cutoff, so the whole app uses one line.
    static let modernCutoff = 1985

    /// Modern enough for a genre row? A title with no known production year is treated as NOT modern
    /// (excluded from rows) — the server-side year filter on the Home path excludes year-less items
    /// the same way, so both surfaces agree.
    static func isModern(_ item: BaseItemDto) -> Bool {
        guard let year = item.productionYear else { return false }
        return year >= modernCutoff
    }

    /// Modern titles only, original order preserved — for the genre ROWS (a hard cut).
    static func modernOnly(_ items: [BaseItemDto]) -> [BaseItemDto] {
        items.filter(isModern)
    }
}
