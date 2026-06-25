//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Nuke

// MARK: - BrunoPosterPrefetcher

//
// Warms a shelf's poster images so a freshly-revealed (or horizontally-scrolled) row isn't blank.
// Bruno-owned and additive — it does NOT touch the stock Poster components; a Bruno shelf view owns
// one and drives it from onAppear/onDisappear.
//
// Two invariants make this actually warm the cache the cells read (INV-4):
//   1. Same pipeline as the cells — `.Swiftfin.posters` (which is also `ImagePipeline.shared`).
//   2. Same request width as the cells — `BrunoShelfMetrics.posterMaxWidth` mirrors the stock-private
//      `PosterImage` width, so the maxWidth-salted Nuke cache key matches. A different width warms a
//      different key = wasted bandwidth, no hit.
// Prefetch runs at low priority into the memory cache so it never starves a visible cell's load, and
// is cancelled on disappear so fast scrolling can't pile up a prefetch storm.
@MainActor
final class BrunoPosterPrefetcher {

    private let prefetcher: ImagePrefetcher

    /// Warm only the first screenful (+ a little horizontal lookahead). Building `ImageSource`s is
    /// synchronous on the main thread in `onAppear`, so warming the whole ~20-item row on every
    /// shelf that scrolls into view was a per-appear cost during fast vertical nav. A screenful is
    /// the high-value set; the rest warm lazily as the row scrolls.
    private static let warmCount = 10

    init() {
        prefetcher = ImagePrefetcher(pipeline: .Swiftfin.posters, destination: .memoryCache)
        prefetcher.priority = .low
    }

    func warm(_ items: some Sequence<BaseItemDto>, type: PosterDisplayType) {
        prefetcher.startPrefetching(with: posterURLs(items, type: type))
    }

    func stop(_ items: some Sequence<BaseItemDto>, type: PosterDisplayType) {
        prefetcher.stopPrefetching(with: posterURLs(items, type: type))
    }

    private func posterURLs(_ items: some Sequence<BaseItemDto>, type: PosterDisplayType) -> [URL] {
        let width = BrunoShelfMetrics.posterMaxWidth(for: type)
        let quality = BrunoShelfMetrics.posterQuality
        return items.prefix(Self.warmCount).compactMap { item in
            switch type {
            case .landscape:
                item.landscapeImageSources(maxWidth: width, quality: quality).first?.url
            case .portrait:
                item.portraitImageSources(maxWidth: width, quality: quality).first?.url
            case .square:
                item.squareImageSources(maxWidth: width, quality: quality).first?.url
            }
        }
    }
}
