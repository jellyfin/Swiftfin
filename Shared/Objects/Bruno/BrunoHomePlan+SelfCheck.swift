//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if DEBUG
import Foundation
import JellyfinAPI

// MARK: - BrunoHomePlan determinism self-check (DEBUG only)

//
// There is no XCTest target in this fork, so the determinism contract (plan §D / DoD) is
// enforced as a DEBUG runtime invariant: `BrunoHomeViewModel.init` asserts this passes.
// The RNG itself is additionally verified against the captured JS sequence by
// `bruno-verify/run.sh`. Asserts: same seed ⇒ same shelves; different seed ⇒ different;
// no two adjacent query shelves share a kind; empty `.items` groups are dropped.
extension BrunoHomePlan {

    static func selfCheckPassed() -> Bool {
        let mock = mockSnapshot()

        let a = build(seed: 4242, snapshot: mock).map(\.id)
        let b = build(seed: 4242, snapshot: mock).map(\.id)
        let c = build(seed: 9999, snapshot: mock).map(\.id)

        guard a == b else { return false } // stable for a fixed seed
        guard a != c else { return false } // varies by seed

        let shelves = build(seed: 4242, snapshot: mock)
        for index in 1 ..< shelves.count where shelves[index].kindTag.hasPrefix("query") {
            if shelves[index].kindTag == shelves[index - 1].kindTag { return false }
        }

        // A group with < minItems children must drop its `.items` shelf (here: Eras).
        let sparse = BrunoLibrarySnapshot(
            favoriteGroupBoxSets: boxSets("g", 7),
            childrenByGroupName: ["Decades": boxSets("d", 1)],
            genres: ["Drama"],
            years: [1999]
        )
        guard !build(seed: 1, snapshot: sparse).contains(where: { $0.id == "eras" }) else { return false }

        return true
    }

    private static func boxSets(_ prefix: String, _ count: Int) -> [BaseItemDto] {
        (0 ..< count).map { BaseItemDto(id: "\(prefix)\($0)", name: "\(prefix.uppercased()) \($0)") }
    }

    private static func mockSnapshot() -> BrunoLibrarySnapshot {
        BrunoLibrarySnapshot(
            favoriteGroupBoxSets: boxSets("group", 7),
            childrenByGroupName: [
                "Directors": boxSets("dir", 8),
                "Studios": boxSets("studio", 8),
                "Decades": boxSets("decade", 8),
                "Genres": boxSets("gnre", 6),
                "Curated": boxSets("cur", 5),
                "Seasonal": boxSets("seas", 4),
            ],
            genres: ["Action", "Comedy", "Drama", "Horror", "Sci-Fi", "Thriller", "Romance", "Crime"],
            years: [1965, 1972, 1984, 1994, 1999, 2003, 2010, 2017, 2021]
        )
    }
}
#endif
