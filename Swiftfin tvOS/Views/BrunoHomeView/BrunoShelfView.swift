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

                // New Releases (the .recentlyAdded spine shelf) shows the full release date in the
                // poster subtitle line — movies' item.subtitle is nil there, so BrunoTitleDateContentView
                // fills the already-reserved blank line (INV-1 row height unchanged). Every other shelf
                // omits the label argument and renders PosterHStack's default TitleSubtitleContentView
                // byte-identically.
                // INV-1: Pin EVERY shelf (portrait AND landscape) so the LazyVStack stops re-reading
                // CollectionHStack's intrinsic height on vertical focus moves — that renegotiation is
                // the up/down "math conflict" that hard-snaps the row with no intervening frames. It
                // also keeps the spine geometry constant while shelves stream in. Both heights are the
                // single source of truth in BrunoShelfMetrics (see docs/BRUNO_PERF_INVARIANTS.md). The
                // pinned height is identical in both branches — the only difference is the New Releases
                // poster label — so the row geometry is unchanged.
                if viewModel.shelf.kind == .recentlyAdded {
                    PosterHStack(
                        title: nil,
                        type: viewModel.posterType,
                        items: viewModel.items,
                        action: { item in
                            router.route(to: .item(item: item))
                        },
                        label: { item in
                            BrunoTitleDateContentView(item: item)
                        }
                    )
                    .frame(height: BrunoShelfMetrics.shelfRowHeight(for: viewModel.posterType))
                } else {
                    PosterHStack(
                        title: nil,
                        type: viewModel.posterType,
                        items: viewModel.items
                    ) { item in
                        router.route(to: .item(item: item))
                    }
                    .frame(height: BrunoShelfMetrics.shelfRowHeight(for: viewModel.posterType))
                }
            }
            .onAppear {
                prefetcher.warm(viewModel.items.elements, type: viewModel.posterType)
            }
            .onDisappear {
                prefetcher.stop(viewModel.items.elements, type: viewModel.posterType)
            }
            // Debug HUD instrumentation (inert unless a debug overlay is on): count shelf redraws
            // and track the shelf's vertical movement — the up/down "graphic math" the perf
            // invariants fight. See Shared/Objects/Bruno/BrunoDebugInstrument.swift.
            .brunoDebugRedraw("shelf:\(viewModel.title)")
            .brunoDebugLayout("shelf:\(viewModel.title)")
        }
    }
}
