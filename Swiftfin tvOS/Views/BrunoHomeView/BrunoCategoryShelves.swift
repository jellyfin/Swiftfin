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
    /// New Releases only: render each poster's full release date on line 2 — on the inline shelf AND
    /// the dated "Show all" grid. Default false ⇒ every other category renders the shared label.
    let showsDate: Bool
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
        showsDate: Bool = false,
        gridParent: BaseItemDto? = nil,
        gridYear: Int? = nil
    ) {
        self.boxSet = boxSet
        self.children = children
        self.drillStyle = drillStyle
        self.lens = lens
        self.recencyBiased = recencyBiased
        self.showsDate = showsDate
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

extension BrunoCollectionCategory {

    /// Fixed top-shelf order (owner request); unknown names fall to the end. Shared by the Collections
    /// hub and the Home feed's terminal footer so both order the group tiles identically. Seasonal is
    /// promoted to 2nd place (after New Releases) for the Halloween→Christmas window
    /// (`BrunoCollectionArtwork.seasonalPromoted`); the rest shift down one. Default last slot otherwise.
    static func rank(for name: String, on date: Date = Date()) -> Int {
        let order = BrunoCollectionArtwork.seasonalPromoted(on: date)
            ? [
                "new releases": 0, "seasonal": 1, "genres": 2, "directors": 3,
                "boxed sets": 4, "decades": 5, "curated": 6, "studios": 7,
            ]
            : [
                "new releases": 0, "genres": 1, "directors": 2, "boxed sets": 3,
                "decades": 4, "curated": 5, "studios": 6, "seasonal": 7,
            ]
        return order[name.lowercased()] ?? .max
    }

    /// What "Show all" does for a group.
    static func drillStyle(for groupName: String) -> DrillStyle {
        switch groupName.lowercased() {
        case "genres": .genres // core-category panel + mixed sub-genre shelves (§4 + core panel)
        case "decades": .shelves // shelf per decade (§4)
        case "curated": .shelves // shelf per curated sub-collection (Asian Cinema, Oscar Buzz, …)
        default: .grid // flat full grid (§3)
        }
    }

    /// Per-category lens eyebrow so each shelf reads with its own flavor instead of a flat repeated
    /// surface eyebrow (matches Home's lens variety). nil → surface default.
    static func lens(for groupName: String) -> String? {
        switch groupName.lowercased() {
        case "directors": "Auteurs"
        case "studios": "From the Vault"
        case "curated": "Hand-Picked"
        case "decades": "Through the Years"
        case "new releases": "Just Added"
        case "seasonal": "In Season"
        default: nil
        }
    }

    /// The favorited "group" tiles (Directors, Decades, …) built purely from a loaded snapshot — NO
    /// network — in the fixed order, dropping empties. Excludes the synthetic "Boxed Sets" category
    /// (that needs its own box-set fetch). Reused by the Collections hub and the Home feed's footer.
    static func fromSnapshot(_ snapshot: BrunoLibrarySnapshot) -> [BrunoCollectionCategory] {
        snapshot.favoriteGroupBoxSets
            .compactMap { boxSet -> BrunoCollectionCategory? in
                guard let name = boxSet.name else { return nil }
                let children = snapshot.childrenByGroupName[name] ?? []
                guard children.isNotEmpty else { return nil }
                return BrunoCollectionCategory(
                    boxSet: boxSet,
                    children: children,
                    drillStyle: drillStyle(for: name),
                    lens: lens(for: name),
                    showsDate: name.lowercased() == "new releases"
                )
            }
            .enumerated()
            .sorted { lhs, rhs in
                let l = rank(for: lhs.element.name), r = rank(for: rhs.element.name)
                return l != r ? l < r : lhs.offset < rhs.offset
            }
            .map(\.element)
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
    /// When this key changes, the surface scroll-jumps so the selector/pill region sits at the top —
    /// the "pills near top, first shelf in full view" framing you otherwise only reach by focusing a
    /// shelf. Driven by the COMMITTED selection (e.g. the debounced `selectedDecade`), so a fast pill
    /// scrub scrolls once on settle rather than per pill. nil (the default) ⇒ no scroll-jumps.
    var pillScrollKey: String?

    @Router
    private var router

    @Namespace
    private var namespace

    /// INV-9: collapse the pill-select scroll-jump to an instant move when reduce-motion is on.
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    /// Scroll anchor for the selector/pill region — `pillScrollKey` jumps the view here.
    private enum ScrollAnchor: Hashable {
        case selector
    }

    /// Items previewed in each shelf before the trailing "Show all" card. Kept small: a shelf is a
    /// preview, and every card is a focusable UIHostingController, so realizing fewer per row is the
    /// dominant lever on vertical-scroll cost. "Show all" covers the rest.
    private let shelfCap = 14

    /// Cap-and-grow window: how many shelves are mounted right now. Starts small so entering a
    /// surface (or selecting a decade) doesn't mount every CollectionHStack at once — the synchronous
    /// per-cell UIHostingController mount burst that froze the main thread. Grows append-only as the
    /// user scrolls (a bottom sentinel), and resets when the category set changes (decade swap / load).
    @State
    private var visibleShelfCount = 4

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
        ScrollViewReader { proxy in
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
                            // Pill/selector region (Decades pills, Genres core panel): the scroll target.
                            .id(ScrollAnchor.selector)
                    }

                    if showCategoryRow {
                        BrunoCategoryCardRow(categories: categories)
                            .padding(.top, (header == nil && featured == nil) ? 20 : 0)
                            // Mutually exclusive with `header`; anchored too so any selector-row surface
                            // that adopts pillScrollKey lands here.
                            .id(ScrollAnchor.selector)
                    }

                    ForEach(categories.prefix(visibleShelfCount)) { category in
                        shelf(for: category)
                    }

                    // Grow the mounted window as the user nears the bottom (append-only — INV-2 keeps focus/identity).
                    if visibleShelfCount < categories.count {
                        Color.clear
                            .frame(height: 1)
                            .onAppear { visibleShelfCount = min(visibleShelfCount + 4, categories.count) }
                    }
                }
                .padding(.bottom, 60)
            }
            // Jump to the "pills near top, first shelf in full view" framing when the COMMITTED pill
            // selection settles (onChange fires on real changes only, so the cold-enter hero-intro
            // framing — INV-7 — is left untouched). INV-9: instant under reduce-motion.
            .onChange(of: pillScrollKey) { _, _ in
                let jump = { proxy.scrollTo(ScrollAnchor.selector, anchor: .top) }
                if reduceMotion {
                    jump()
                } else {
                    withAnimation(.easeInOut(duration: 0.35)) { jump() }
                }
            }
            .onChange(of: categories.map(\.id)) { _, _ in
                visibleShelfCount = 4
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
                onShowAll: { brunoRouteToShowAll(category, router: router, namespace: namespace) },
                artCarousel: ["studios", "directors"].contains(category.name.lowercased()),
                // Per-category opt-in (New Releases) on top of the surface-wide flag (Decades).
                showsDate: showsDate || category.showsDate,
                labelArt: Self.labelArtStyle(for: category.name)
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
            // Boxed Sets: weighted-random preview (bigger franchises bubble up), capped to 16 before
            // the "Show all" card, which still lists every set. Reshuffles daily.
            return Self.weightedPreview(items, count: 16, salt: 0xB075)
        case .grid:
            // Box-set groups (Directors, Studios, …) "Show all" to a flat grid of these exact
            // box-set children — the row IS the full set, so populate all. Flat MOVIE groups
            // (no box-set children, e.g. New Releases) instead "Show all" to a live paged library
            // of every contributing movie, so their inline row stays a capped preview.
            let hasBoxSetChildren = category.children.contains { $0.type == .boxSet }
            guard hasBoxSetChildren else { return Array(items.prefix(shelfCap)) }
            // Studios / Directors: a weighted-random "cream of the crop" preview — collections with
            // more titles in the library bubble up, reshuffled daily for freshness. Capped to 16
            // before the "Show all" card; "Show all" still lists every one, so the cap only curates.
            if category.name.lowercased() == "studios" {
                return Self.weightedPreview(items, count: 16, salt: 0x5747)
            }
            return Self.weightedPreview(items, count: 16, salt: 0x91A3)
        case .genres:
            // Genres: same weighted-random preview (sub-genres with more films bubble up); "Show all"
            // opens the full genres surface, so the cap only curates the row.
            return Self.weightedPreview(items, count: shelfCap, salt: 0xC0DE)
        case .shelves:
            // "Show all" opens a richer drill-in (shelf-per-sub-group, e.g. Decades): simple preview.
            return Array(items.prefix(shelfCap))
        }
    }

    /// Genres / Decades render their items with the category-tile treatment (title over cycling
    /// film art) instead of poster-with-title-below. Genres keep their representative poster at rest;
    /// Decades fall back to a brand gradient (their box-set poster bakes the label into the bitmap).
    /// nil ⇒ standard poster cells.
    private static func labelArtStyle(for groupName: String) -> BrunoLabelArtStyle? {
        switch groupName.lowercased() {
        case "genres": .poster
        case "decades": .gradient(top: Color(hex: "201408"), bottom: Color(hex: "9C6A1E"))
        default: nil
        }
    }

    /// A group shelf should show its sub-COLLECTIONS, not the loose movies inside each one
    /// (the Directors shelf was listing every director's movies after the directors). Show only
    /// the box sets; fall back to all children for a genuinely flat group (e.g. New Releases).
    private func subCollections(of category: BrunoCollectionCategory) -> [BaseItemDto] {
        let boxSets = category.children.filter { $0.type == .boxSet }
        return boxSets.isEmpty ? category.children : boxSets
    }

    /// Day-stable base seed (same lineup all day, refreshes tomorrow). Mirrors BrunoBoxSetShelvesView.
    private static var dailySeed: UInt32 {
        UInt32(truncatingIfNeeded: Int(Date().timeIntervalSince1970 / 86400))
    }

    /// `weightBias` < 1 dampens the title-count weight so the heavyweights bubble up without the row
    /// going static — bigger = stronger "cream of the crop", smaller = more rotation.
    private static let weightBias = 0.6

    /// Weighted-random preview favouring collections with more titles in the library (Efraimidis–
    /// Spirakis: key = u^(1/weight), keep the highest `count`). Seeded per-shelf (via `salt`) so each
    /// row rotates independently but stays stable within a day. Used by Studios / Directors / Genres.
    private static func weightedPreview(_ items: [BaseItemDto], count: Int, salt: UInt32) -> [BaseItemDto] {
        guard items.count > count else { return items }
        var rng = BrunoRNG(seed: dailySeed &+ salt)
        var keyed: [(item: BaseItemDto, key: Double)] = []
        keyed.reserveCapacity(items.count)
        for item in items {
            let weight = pow(Double(max(item.childCount ?? 1, 1)), weightBias)
            let u = max(rng.nextUnit(), 1e-9)
            keyed.append((item, pow(u, 1.0 / weight)))
        }
        return keyed.sorted { $0.key > $1.key }.prefix(count).map(\.item)
    }
}
