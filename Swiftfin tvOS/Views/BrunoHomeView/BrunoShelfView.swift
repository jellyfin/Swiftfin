//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// MARK: - BrunoShelfView

//
// One horizontal carousel: a Bruno-styled header (accent eyebrow + Oswald title) over the
// stock tvOS `PosterHStack`, which gives native focus, scaling and the card → stock detail
// route for free (plan §C1/§C4). Guarded on `isNotEmpty` like `LatestInLibraryView`.
struct BrunoShelfView: View {

    @ObservedObject
    var viewModel: BrunoShelfViewModel

    @Router
    private var router

    // INV-4: warms this row's posters into the same pipeline at the same width the cells request,
    // so a freshly-revealed or horizontally-scrolled row isn't blank. Cancelled on disappear.
    @State
    private var prefetcher = BrunoPosterPrefetcher()

    var body: some View {
        if viewModel.items.isNotEmpty {
            VStack(alignment: .leading, spacing: 2) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.lens.uppercased())
                        .font(.brunoBody(20, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(Color.bruno.accent)

                    Text(viewModel.title)
                        .font(.brunoDisplay(36, weight: .semibold))
                        .foregroundStyle(Color.bruno.fg)
                }
                .padding(.horizontal, 50)

                PosterHStack(
                    title: nil,
                    type: viewModel.posterType,
                    items: viewModel.items
                ) { item in
                    router.route(to: .item(item: item))
                }
                // INV-1: Pin portrait shelves so the LazyVStack stops re-reading CollectionHStack's
                // intrinsic height on vertical focus moves (the up/down "math conflict" hitch) and
                // so the spine geometry stays constant while shelves stream in. Height is the single
                // source of truth in BrunoShelfMetrics (see docs/BRUNO_PERF_INVARIANTS.md).
                // Landscape rows keep their intrinsic height (nil) — different aspect, no clip risk.
                .frame(height: viewModel.posterType == .portrait ? BrunoShelfMetrics.shelfRowHeight : nil)
            }
            .onAppear {
                prefetcher.warm(viewModel.items.elements, type: viewModel.posterType)
            }
            .onDisappear {
                prefetcher.stop(viewModel.items.elements, type: viewModel.posterType)
            }
        }
    }
}
