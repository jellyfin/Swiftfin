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

// MARK: - BrunoCollectionCategory

//
// One group/sub-group (a BoxSet) plus its child items. Shared by the Collections hub and the
// Genres/Decades drill-in, which render identically — only their data source differs.
struct BrunoCollectionCategory: Identifiable {

    /// What "Show all" does for this category.
    enum DrillStyle {
        /// Flat full grid for the group (a stock ItemLibrary). The default leaf behaviour.
        case grid
        /// Shelf-per-sub-group drill-in (Decades).
        case shelves
        /// The Genres page: a core-category panel on top, then the mixed sub-genre shelves.
        case genres
        /// A grid of this category's own `children` — for synthetic categories with no parent
        /// BoxSet (e.g. Boxed Sets, a computed set of box sets).
        case items
    }

    let boxSet: BaseItemDto
    let children: [BaseItemDto]
    let drillStyle: DrillStyle
    /// Per-category lens eyebrow ("Auteurs" for Directors, …). Falls back to the surface eyebrow.
    let lens: String?

    init(boxSet: BaseItemDto, children: [BaseItemDto], drillStyle: DrillStyle = .grid, lens: String? = nil) {
        self.boxSet = boxSet
        self.children = children
        self.drillStyle = drillStyle
        self.lens = lens
    }

    var id: String {
        boxSet.id ?? boxSet.displayTitle
    }

    var name: String {
        boxSet.displayTitle
    }
}

/// The single item to feature in a browse surface's hero banner: the first movie/series WITH a
/// backdrop image across the categories' children, else the first such item, else nil. Keeps the
/// hero to real watchable content (group BoxSets frequently lack backdrops, movies reliably have them).
func brunoFeaturedItem(in categories: [BrunoCollectionCategory]) -> BaseItemDto? {
    let leaves = categories
        .flatMap(\.children)
        .filter { $0.type == .movie || $0.type == .series }
    return leaves.first(where: { $0.backdropImageTags?.isNotEmpty == true }) ?? leaves.first
}

// MARK: - BrunoCategoryShelves

//
// The reusable browse surface: a category row that scroll-jumps to each shelf, then one capped
// horizontal shelf per category, each header carrying a "Show all" to the full grid (or a
// further shelf view). Reuses the stock PosterHStack for native focus/scaling.
struct BrunoCategoryShelves: View {

    let categories: [BrunoCollectionCategory]
    let eyebrow: String
    /// Optional content rendered above everything (e.g. the Genres core-category panel).
    var header: AnyView?
    /// The scroll-jump chip row. Hidden when a header replaces it (e.g. the Genres main page).
    var showCategoryRow: Bool = true
    /// A single featured item for the cinematic hero banner atop the surface (nil → no hero row).
    var featured: BaseItemDto?
    /// Eyebrow shown on the hero banner ("Featured", "Featured Film", …).
    var heroEyebrow: String = "Featured"

    @Router
    private var router

    @Namespace
    private var namespace

    /// Items previewed in each shelf before the trailing "Show all" card. Kept small: a shelf is a
    /// preview, and every card is a focusable UIHostingController, so realizing fewer per row is the
    /// dominant lever on vertical-scroll cost. "Show all" covers the rest.
    private let shelfCap = 14

    var body: some View {
        ZStack {
            // Ambient as a SIBLING layer (matching BrunoHomeView — the smooth surface), NOT a
            // .background of the ScrollView. Keeps the radius-90 blur out of the ScrollView's
            // per-frame compositing so it doesn't re-rasterize during the focus-driven
            // scroll-to-reveal animation (the residual vertical-scroll hitch).
            BrunoAmbientBackground(item: featured)

            scrollContent
        }
    }

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 36) {
                // Full-bleed cinematic hero (Home pattern): a row in the same scroll plane as the
                // shelves, so vertical focus traverses hero <-> content with no special handling.
                if let featured {
                    BrunoHeroView(items: [featured], index: .constant(0), eyebrow: heroEyebrow)
                }

                if let header {
                    header
                        .padding(.top, featured == nil ? 20 : 0)
                }

                if showCategoryRow {
                    categoryCardRow
                        .padding(.top, (header == nil && featured == nil) ? 20 : 0)
                }

                ForEach(categories) { category in
                    shelf(for: category)
                }
            }
            .padding(.bottom, 60)
        }
    }

    // The big gradient category cards (the group artwork). Tapping one jumps straight to that
    // category's full "Show all" destination — no scroll-jump to the inline shelf.
    private var categoryCardRow: some View {
        PosterHStack(
            title: nil,
            type: .portrait,
            // These are navigation tiles, not library items: strip userData so the stock
            // favorite-heart / watched overlays don't decorate the branded category artwork.
            // (The unwatched corner-triangle is driven by canBePlayed and would need a dedicated
            // tile to fully suppress — deferred.)
            items: categories.map { category in
                var card = category.boxSet
                card.userData = nil
                return card
            }
        ) { boxSet in
            let key = boxSet.id ?? boxSet.displayTitle
            if let category = categories.first(where: { $0.id == key }) {
                routeToShowAll(category)
            }
        }
    }

    private func shelf(for category: BrunoCollectionCategory) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            VStack(alignment: .leading, spacing: 0) {
                Text((category.lens ?? eyebrow).uppercased())
                    .font(.brunoBody(20, weight: .semibold))
                    .tracking(3)
                    .foregroundStyle(Color.bruno.accent)

                Text(category.name)
                    .font(.brunoDisplay(36, weight: .semibold))
                    .foregroundStyle(Color.bruno.fg)
            }
            .padding(.horizontal, 50)

            BrunoShelfRow(
                items: shelfItems(for: category),
                onItem: { router.route(to: .item(item: $0)) },
                onShowAll: { routeToShowAll(category) }
            )
        }
    }

    /// The items rendered in a category's inline shelf. The `shelfCap` is a PREVIEW cap: it only
    /// applies when "Show all" leads somewhere richer than the inline row (Decades/Curated → a
    /// shelf-per-sub-group drill-in; Genres → the genres surface). For terminal categories whose
    /// "Show all" is just a flat grid of these same box-set children (Directors, Studios, … →
    /// `.grid`; Boxed Sets → `.items`), the row IS the full set, so we populate everything — the
    /// cap there would only hide collections that "Show all" can't add back.
    private func shelfItems(for category: BrunoCollectionCategory) -> [BaseItemDto] {
        let items = subCollections(of: category)
        switch category.drillStyle {
        case .items:
            // Synthetic box-set grid (Boxed Sets): the row mirrors the Show-all grid 1:1.
            return items
        case .grid:
            // Box-set groups (Directors, Studios, …) "Show all" to a flat grid of these exact
            // box-set children — the row IS the full set, so populate all. Flat MOVIE groups
            // (no box-set children, e.g. New Releases) instead "Show all" to a live paged library
            // of every contributing movie, so their inline row stays a capped preview.
            let hasBoxSetChildren = category.children.contains { $0.type == .boxSet }
            return hasBoxSetChildren ? items : Array(items.prefix(shelfCap))
        case .shelves, .genres:
            // "Show all" opens a richer drill-in (shelf-per-sub-group / genres surface): preview.
            return Array(items.prefix(shelfCap))
        }
    }

    /// A group shelf should show its sub-COLLECTIONS, not the loose movies inside each one
    /// (the Directors shelf was listing every director's movies after the directors). Show only
    /// the box sets; fall back to all children for a genuinely flat group (e.g. New Releases).
    private func subCollections(of category: BrunoCollectionCategory) -> [BaseItemDto] {
        let boxSets = category.children.filter { $0.type == .boxSet }
        return boxSets.isEmpty ? category.children : boxSets
    }

    private func routeToShowAll(_ category: BrunoCollectionCategory) {
        switch category.drillStyle {
        case .genres:
            router.route(to: .brunoGenres(parent: category.boxSet, core: nil))
        case .shelves:
            router.route(to: .brunoCategoryShelves(parent: category.boxSet), in: namespace)
        case .items:
            router.route(to: .brunoItemsGrid(title: category.name, items: category.children), in: namespace)
        case .grid:
            // A group whose children are sub-collections (Directors, Studios, …) must show ONLY
            // those box sets on "Show all". The stock ItemLibrary(parent:) query returns the
            // group's movies recursively as well — that's the "all the contributing movies are
            // listed after the directors" bug. Render a static grid of just the box-set children
            // instead (same filter the inline shelf uses). Flat movie groups (no box-set children,
            // e.g. New Releases) keep the live, paged library.
            let boxSetChildren = category.children.filter { $0.type == .boxSet }
            if boxSetChildren.isNotEmpty {
                router.route(to: .brunoItemsGrid(title: category.name, items: boxSetChildren), in: namespace)
            } else if category.boxSet.libraryType == .boxSet {
                router.route(
                    to: .library(library: ItemLibrary(parent: category.boxSet, filters: .default)),
                    in: namespace
                )
            } else {
                // Not a BoxSet: ItemLibrary(parent:) would fall through to an unscoped, whole-
                // library query, so open the item detail instead.
                router.route(to: .item(item: category.boxSet))
            }
        }
    }
}
