//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// MARK: - BrunoItemPaging

//
// A tiny `startIndex` paging loop for Bruno's "final-destination" grids (the A–Z Movies/TV grid and
// the Kids grid). Those surfaces render a hero + grid in ONE shared scroll plane, so they can't ride
// `PagingLibraryViewModel`/`CollectionVGrid` (a nested scroller would break hero<->grid focus
// traversal). They keep an in-place `LazyVGrid` over a `@Published [BaseItemDto]`, and use this to
// fill that array to completion instead of capping at a single hard-limited request.
//
// The caller supplies a parameters builder (so each surface keeps its own `GetItems` shape). This
// helper ONLY fetches + appends raw pages — no sorting, dedupe, or filtering happens inside the loop;
// the caller does that ONCE after the full set is returned.
enum BrunoItemPaging {

    /// First-page (and per-page) size. Kept large so the common case (a set that fits in one page)
    /// is a SINGLE request via the short-page early-exit below.
    static let pageSize = 200

    /// Defensive cap on iterations so a non-advancing / misbehaving server can never spin an
    /// unbounded loop. 50 * 200 = 10,000 items, far above the real library scale.
    static let maxIterations = 50

    /// Loop `GetItems` by `startIndex`, appending every page, until the set is exhausted.
    ///
    /// - Parameter client: the session's `JellyfinClient`.
    /// - Parameter makeParameters: builds the request for a given `startIndex` + `limit`. The caller
    ///   owns every other field (userID, includeItemTypes, sortBy, fields, …).
    /// - Returns: the full, untransformed `[BaseItemDto]` (caller sorts/dedupes/filters once after).
    ///
    /// Stop condition: a page with `count < limit` means the server is exhausted (matches
    /// `PagingLibraryViewModel.__actuallyGetNextPage` `hasNextPage = !(count < pageSize)`), so we stop
    /// WITHOUT issuing one more (would-be-empty) round-trip.
    ///
    /// Offset model: `startIndex` advances by the ACCUMULATED count each iteration, so a server that
    /// returns fewer than `limit` mid-stream still keeps a contiguous window.
    static func fetchAll(
        client: JellyfinClient,
        makeParameters: (_ startIndex: Int, _ limit: Int) -> Paths.GetItemsParameters
    ) async throws -> [BaseItemDto] {
        var all: [BaseItemDto] = []

        for _ in 0 ..< maxIterations {
            let parameters = makeParameters(all.count, pageSize)
            let page = try await client.send(Paths.getItems(parameters: parameters)).value.items ?? []

            all.append(contentsOf: page)

            // Short page (incl. empty) ⇒ server exhausted; stop here (early-exit covers the common
            // single-request case). A non-advancing server (empty page) also lands here.
            if page.count < pageSize { break }
        }

        return all
    }
}
