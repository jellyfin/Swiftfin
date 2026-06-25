//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// MARK: - BrunoHomePayload

//
// Everything Home needs to paint the spine instantly on a relaunch, before any network. The
// snapshot reproduces the `.items` (group-tile) shelves via the pure plan, so only the `.query`
// shelves' realized items need caching; `.resume`/`.nextUp`/`.recentlyAdded` are LIVE user-state
// and are intentionally NOT persisted (a stale "Continue Watching" is a correctness bug, not just
// staleness — INV-5). The hero superset pool is persisted (not the 5 random picks — the hero is
// intentionally re-shuffled per entry).
struct BrunoHomePayload: Codable {

    let savedAt: Date
    let userID: String
    /// The day-stable seed this payload was built under. A hydrate is only used when it matches the
    /// current seed, so Shuffle (which reseeds) never paints a stale-seed spine (INV-5).
    let seed: UInt32
    let snapshot: BrunoLibrarySnapshot
    let heroSuperset: [BaseItemDto]
    /// Realized items for `.query` shelves only, keyed by `shelf.id`.
    let queryItems: [String: [BaseItemDto]]
}

// MARK: - BrunoHomeCache

//
// Disk persistence for the Home render payload. An `actor`, so its JSON encode/decode and file I/O
// run OFF the main actor (the `@MainActor` BrunoHomeViewModel must never block first paint on a fat
// snapshot encode). Best-effort and `try?`-tolerant throughout: a missing/corrupt file or a schema
// drift across app versions reads as a cache miss, never a crash. Keyed by userID. The owner has
// granted the app free rein to cache library data locally.
actor BrunoHomeCache {

    static let shared = BrunoHomeCache()

    private var fileURL: URL? {
        try? FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("bruno-home-payload.json")
    }

    /// Returns the persisted payload iff it's for this user, built under `seed`, and younger than
    /// `maxAge`. All guards must pass — otherwise the caller does a normal network refresh.
    func load(userID: String, seed: UInt32, maxAge: TimeInterval) -> BrunoHomePayload? {
        guard let fileURL,
              let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder().decode(BrunoHomePayload.self, from: data),
              payload.userID == userID,
              payload.seed == seed,
              Date().timeIntervalSince(payload.savedAt) < maxAge
        else { return nil }
        return payload
    }

    func store(_ payload: BrunoHomePayload) {
        guard let fileURL, let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
