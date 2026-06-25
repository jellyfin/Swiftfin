//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// Prototype copy is English-only; localization (L10n) is a deferred TODO (see BRUNO_NOTES.md).
// swiftlint:disable hard_coded_display_string

// MARK: - BrunoStudiosGridView (tvOS only)

//
// The Studios "Show all" screen, built as a LITERAL copy of the stock item detail page
// (ItemView.CinematicScrollView) — that's the "in-studio focus" look the owner wants applied to the
// parent selection screen. Same structure, line-for-line:
//   • a full-bleed backdrop image filling the whole screen, edge to edge (here a fixed Hollywood-sign
//     still instead of the per-item backdrop),
//   • a tall hero header (screen height − 150) with the "Studios" title over it,
//   • the grid of studio cards as the scrolling content,
//   • the SAME BlurView(.dark) + gradient-mask `.background` on the scrolling stack, so as you scroll
//     up the image blurs and its colors descend behind the grid.
//
// NOTE on perf: this deliberately uses the ScrollView-`.background` blur that INV-6
// (docs/BRUNO_PERF_INVARIANTS.md) cautions against for recycling grids — because that scroll-coupled
// blur IS the descending-colors effect, and matching the detail page exactly is the explicit ask.
// The grid is a lazy LazyVGrid (only visible cells realize) over ~92 studios; if scroll ever feels
// heavy, the lever is the header height / blur, not the structure.
struct BrunoStudiosGridView: View {

    let title: String
    let items: [BaseItemDto]

    @Router
    private var router

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: EdgeInsets.edgePadding),
        count: 4
    )

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Full-bleed backdrop — fills the entire screen, no band, no inset (mirrors the
                // detail page's ImageView layer). Image(_:) loads the asset-catalog still; the app's
                // ImageView is URL-only and can't.
                Image("BrunoStudiosBackdrop")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                            .frame(height: proxy.size.height - 150)
                            .padding(.bottom, 50)

                        grid
                    }
                    .background {
                        BlurView(style: .dark)
                            .mask {
                                VStack(spacing: 0) {
                                    LinearGradient(gradient: Gradient(stops: [
                                        .init(color: .white, location: 0),
                                        .init(color: .white.opacity(0.7), location: 0.4),
                                        .init(color: .white.opacity(0), location: 1),
                                    ]), startPoint: .bottom, endPoint: .top)
                                        .frame(height: proxy.size.height - 150)

                                    Color.white
                                }
                            }
                    }
                }
            }
        }
        .ignoresSafeArea()
        // Draw our own cinematic title instead of the system nav title (other full-screen Bruno
        // surfaces suppress it the same way).
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Header

    // The "Studios" title, bottom-left over the backdrop — the place the detail page puts the studio
    // logo/title.
    private var header: some View {
        VStack(alignment: .leading) {
            Spacer()
            Text(title)
                .font(.brunoDisplay(72, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 12, y: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 50)
    }

    // MARK: Grid

    // Landscape studio cards, 4 across — same cells as before, just laid out in a LazyVGrid so they
    // can live inside the cinematic ScrollView.
    private var grid: some View {
        LazyVGrid(columns: columns, spacing: EdgeInsets.edgePadding) {
            ForEach(items, id: \.id) { item in
                BrunoArtCarouselCard(item: item, type: .landscape) {
                    router.route(to: .item(item: item))
                } label: {
                    PosterButton<BaseItemDto>.TitleSubtitleContentView(item: item)
                }
            }
        }
        .padding(.horizontal, EdgeInsets.edgePadding)
        .padding(.bottom, 50)
    }
}

// MARK: - NavigationRoute

extension NavigationRoute {

    @MainActor
    static func brunoStudiosGrid(
        title: String,
        items: [BaseItemDto]
    ) -> NavigationRoute {
        NavigationRoute(
            id: "bruno-studios-grid-\(title.lowercased())",
            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
        ) {
            BrunoStudiosGridView(title: title, items: items)
        }
    }
}
