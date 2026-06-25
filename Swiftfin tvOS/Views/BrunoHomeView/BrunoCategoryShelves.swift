//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import SwiftUI

// Prototype copy is English-only; localization (L10n) is a deferred TODO (see BRUNO_NOTES.md).
// swiftlint:disable hard_coded_display_string

// MARK: - BrunoCollectionCategory

//
// One group/sub-group (a BoxSet) plus its child items. Shared by the Collections hub and the
// Genres/Decades drill-in, which render identically — only their data source differs.
// Implicitly Sendable (all members are Sendable: BaseItemDto is Sendable, DrillStyle has no
// associated values), so the loaded category set crosses into the actor-isolated drill-in cache
// (BrunoBoxSetShelvesCache) without ceremony.
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
    /// Genre categories are recency-biased: their row is modern-only and their "Show all" grid sorts
    /// newest-first so pre-1985 films sink to the bottom of the barrel. Non-genre categories don't.
    let recencyBiased: Bool
    /// `.grid` Show-all override: when set, "Show all" opens a live, fully-paged `ItemLibrary` scoped
    /// to `gridParent` (filtered to `gridYear` when non-nil) instead of deriving the parent from
    /// `boxSet`. Used by the per-year decade shelves, whose `boxSet` is a synthetic label-only stub
    /// (no real id/type) — routing must point at the REAL decade BoxSet, narrowed to one year.
    let gridParent: BaseItemDto?
    let gridYear: Int?

    init(
        boxSet: BaseItemDto,
        children: [BaseItemDto],
        drillStyle: DrillStyle = .grid,
        lens: String? = nil,
        recencyBiased: Bool = false,
        gridParent: BaseItemDto? = nil,
        gridYear: Int? = nil
    ) {
        self.boxSet = boxSet
        self.children = children
        self.drillStyle = drillStyle
        self.lens = lens
        self.recencyBiased = recencyBiased
        self.gridParent = gridParent
        self.gridYear = gridYear
    }

    var id: String {
        boxSet.id ?? boxSet.displayTitle
    }

    var name: String {
        boxSet.displayTitle
    }
}

/// Whether an item may appear on a hero banner. Excludes anything tagged Horror (substring, so
/// "Horror Comedy" / "Post-Horror" are caught too): a hero backdrop is full-bleed and unskippable,
/// and even a horror still can be too much for a child glancing at the screen (owner request). A
/// nil `genres` (field not requested) is treated as eligible rather than over-rejecting — callers
/// that rely on this for safety MUST request `.genres` on their fetch.
func brunoHeroEligible(_ item: BaseItemDto) -> Bool {
    guard let genres = item.genres else { return true }
    return !genres.contains { $0.localizedCaseInsensitiveContains("horror") }
}

/// The single item to feature in a browse surface's hero banner: the first movie/series WITH a
/// backdrop image across the categories' children, else the first such item, else nil. Keeps the
/// hero to real watchable content (group BoxSets frequently lack backdrops, movies reliably have
/// them) and never a Horror title (`brunoHeroEligible`).
func brunoFeaturedItem(in categories: [BrunoCollectionCategory]) -> BaseItemDto? {
    let leaves = categories
        .flatMap(\.children)
        .filter { ($0.type == .movie || $0.type == .series) && brunoHeroEligible($0) }
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
    /// Decade surface only: show each poster's full release date on line 2. Default false ⇒ every
    /// other surface (Home / Genres / Kids / Collections) renders the shared label byte-identically.
    var showsDate: Bool = false

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
        // Let the ScrollView fill the screen (matching BrunoHomeView) so the hero's full-bleed
        // backdrop reaches the physical edges instead of being clipped at the title-safe inset. The
        // ScrollView still re-insets its own content to the safe area, so shelves stay title-safe.
        .ignoresSafeArea()
    }

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 36) {
                // Full-bleed cinematic hero (Home pattern): a row in the same scroll plane as the
                // shelves, so vertical focus traverses hero <-> content with no special handling.
                if let featured {
                    BrunoHeroView(
                        items: [featured],
                        index: .constant(0),
                        eyebrow: heroEyebrow,
                        bleedsTop: true,
                        // Taller banner shows more of the backdrop (incl. its top), subject centered.
                        extraHeight: 160
                    )
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

    // The big gradient category cards. Code-drawn tiles (BrunoCategoryTile) rather than the group's
    // server poster, so every label renders at a controlled size (fixes the giant "NEW") and the
    // synthetic "Boxed Sets" category gets real art instead of a grey placeholder. Tapping one jumps
    // straight to that category's full "Show all" destination. CollectionHStack (the same primitive
    // BrunoShelfRow uses) keeps native tvOS focus scaling + continuous-leading-edge scroll; .card
    // owns focus so the tile itself stays pure drawing.
    private var categoryCardRow: some View {
        CollectionHStack(
            uniqueElements: categories,
            columns: 7
        ) { category in
            Button {
                routeToShowAll(category)
            } label: {
                BrunoCategoryTile(category: category)
            }
            .buttonStyle(.card)
        }
        .clipsToBounds(false)
        .dataPrefix(categories.count)
        .insets(horizontal: EdgeInsets.edgePadding, vertical: 20)
        .itemSpacing(EdgeInsets.edgePadding - 20)
        .scrollBehavior(.continuousLeadingEdge)
        .focusSection()
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
                onShowAll: { routeToShowAll(category) },
                artCarousel: ["studios", "directors"].contains(category.name.lowercased()),
                showsDate: showsDate
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
            guard hasBoxSetChildren else { return Array(items.prefix(shelfCap)) }
            // Studios: a weighted-random "cream of the crop" preview — studios with more titles in the
            // library bubble up, reshuffled daily for freshness. "Show all" still lists every studio,
            // so capping the row only curates the preview. Other box-set groups (Directors) show all.
            if category.name.lowercased() == "studios" {
                return Self.studiosPreview(items, count: shelfCap)
            }
            return items
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

    /// Day-stable seed (same lineup all day, refreshes tomorrow); salted so it differs from other
    /// seeded shelves. Mirrors BrunoBoxSetShelvesView's day-stable shuffle.
    private static var studiosSeed: UInt32 {
        UInt32(truncatingIfNeeded: Int(Date().timeIntervalSince1970 / 86400)) &+ 0x5747
    }

    /// `bias` < 1 dampens the title-count weight so the majors bubble up without the row going
    /// static — bigger bias = stronger "cream of the crop", smaller = more rotation.
    private static let studiosBias = 0.6

    /// Weighted-random preview favouring studios with more titles in the library. Efraimidis–Spirakis
    /// weighted sampling: key = u^(1/weight), keep the highest `count`. Seeded so it's stable per day.
    private static func studiosPreview(_ items: [BaseItemDto], count: Int) -> [BaseItemDto] {
        guard items.count > count else { return items }
        var rng = BrunoRNG(seed: studiosSeed)
        var keyed: [(item: BaseItemDto, key: Double)] = []
        keyed.reserveCapacity(items.count)
        for item in items {
            let weight = pow(Double(max(item.childCount ?? 1, 1)), studiosBias)
            let u = max(rng.nextUnit(), 1e-9)
            keyed.append((item, pow(u, 1.0 / weight)))
        }
        return keyed.sorted { $0.key > $1.key }.prefix(count).map(\.item)
    }

    private func routeToShowAll(_ category: BrunoCollectionCategory) {
        switch category.drillStyle {
        case .genres:
            router.route(to: .brunoGenres(parent: category.boxSet, core: nil))
        case .shelves:
            router.route(to: .brunoCategoryShelves(parent: category.boxSet), in: namespace)
        case .items:
            // Boxed Sets: landscape cards so the franchise names aren't scrunched, with the
            // collection-name / "Collection" / film-count + year-range lockup.
            router.route(
                to: .brunoBoxSetGrid(
                    title: category.name,
                    items: category.children,
                    posterType: .landscape,
                    collectionLabel: true
                ),
                in: namespace
            )
        case .grid:
            // Per-year decade shelf: route to a live, fully-paged ItemLibrary scoped to the REAL
            // decade BoxSet, filtered to this single year (the inline row is only a preview, so
            // "Show all" must reach the complete year). The synthetic category's own `boxSet` is a
            // label-only stub, so we can't derive the parent from it — `gridParent` carries the real
            // decade BoxSet and `gridYear` the year. "Other" has no single year (gridYear == nil), so
            // it opens the decade's full library unfiltered.
            if let gridParent = category.gridParent {
                let filters: ItemFilterCollection = category.gridYear.map { year in
                    .init(years: [ItemYear(integerLiteral: year)])
                } ?? .default
                router.route(
                    to: .library(library: ItemLibrary(parent: gridParent, filters: filters)),
                    in: namespace
                )
                return
            }

            // A group whose children are sub-collections (Directors, Studios, …) must show ONLY
            // those box sets on "Show all". The stock ItemLibrary(parent:) query returns the
            // group's movies recursively as well — that's the "all the contributing movies are
            // listed after the directors" bug. Render a static grid of just the box-set children
            // instead (same filter the inline shelf uses). Flat movie groups (no box-set children,
            // e.g. New Releases) keep the live, paged library.
            let boxSetChildren = category.children.filter { $0.type == .boxSet }
            if boxSetChildren.isNotEmpty {
                // Studios get the cinematic Hollywood-backdrop grid (landscape cards under a
                // detail-page-style hero band). Directors stay the plain portrait grid (headshots,
                // header-overlap fix).
                let isStudios = category.name.lowercased() == "studios"
                if isStudios {
                    router.route(
                        to: .brunoStudiosGrid(
                            title: category.name,
                            items: boxSetChildren
                        ),
                        in: namespace
                    )
                } else {
                    router.route(
                        to: .brunoBoxSetGrid(
                            title: category.name,
                            items: boxSetChildren,
                            posterType: .portrait,
                            artCarousel: true
                        ),
                        in: namespace
                    )
                }
            } else if category.boxSet.libraryType == .boxSet {
                // Genre grids sort newest-first so the pre-1985 classics sink to the literal bottom
                // of the barrel (owner request) — still reachable, just never up top. Other grids
                // keep the default sortName order.
                let filters: ItemFilterCollection = category.recencyBiased
                    ? .init(sortBy: [.premiereDate], sortOrder: [.descending])
                    : .default
                router.route(
                    to: .library(library: ItemLibrary(parent: category.boxSet, filters: filters)),
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
