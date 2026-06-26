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

// MARK: - BrunoCategoryCardRow

//
// The big gradient category cards (code-drawn `BrunoCategoryTile`, not the group's server poster, so
// every label renders at a controlled size and the synthetic "Boxed Sets" tile gets real art). Shared
// by the Collections/Genres browse surface (`BrunoCategoryShelves`) and the Home feed's terminal
// footer, so a tapped tile drills to the SAME destination from either host (`brunoRouteToShowAll`).
// CollectionHStack (the same primitive `BrunoShelfRow` uses) keeps native tvOS focus scaling +
// continuous-leading-edge scroll; `.card` owns focus so the tile itself stays pure drawing.
struct BrunoCategoryCardRow: View {

    let categories: [BrunoCollectionCategory]

    @Router
    private var router

    @Namespace
    private var namespace

    var body: some View {
        CollectionHStack(
            uniqueElements: categories,
            columns: 7
        ) { category in
            Button {
                brunoRouteToShowAll(category, router: router, namespace: namespace)
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
}

// MARK: - Shared "Show all" routing

//
// "Show all" routing for a collection category — used by BOTH `BrunoCategoryCardRow` (the gradient
// tiles, on Collections and the Home footer) and each shelf header's "Show all" in
// `BrunoCategoryShelves`. Kept in one place so the two entry points can never diverge.
@MainActor
func brunoRouteToShowAll(
    _ category: BrunoCollectionCategory,
    router: Router.Wrapper,
    namespace: Namespace.ID
) {
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
        // Dated flat-movie group (New Releases): route to the Bruno-owned grid so posters carry the
        // full release date — the shared stock paged library can't, and editing it would leak dates
        // app-wide. Newest-first so it reads as "new releases". (No box-set children here.)
        if category.showsDate, !category.children.contains(where: { $0.type == .boxSet }) {
            router.route(
                to: .brunoBoxSetGrid(
                    title: category.name,
                    items: category.children.sorted {
                        ($0.premiereDate ?? .distantPast) > ($1.premiereDate ?? .distantPast)
                    },
                    posterType: .portrait,
                    showsDate: true
                ),
                in: namespace
            )
            return
        }

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
