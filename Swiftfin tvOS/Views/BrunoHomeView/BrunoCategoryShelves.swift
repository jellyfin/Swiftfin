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

    init(boxSet: BaseItemDto, children: [BaseItemDto], drillStyle: DrillStyle = .grid) {
        self.boxSet = boxSet
        self.children = children
        self.drillStyle = drillStyle
    }

    var id: String {
        boxSet.id ?? boxSet.displayTitle
    }

    var name: String {
        boxSet.displayTitle
    }
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

    @Router
    private var router

    @Namespace
    private var namespace

    /// Items shown before "Show all" (roadmap §3: single line, ~12).
    private let shelfCap = 12

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 36) {
                    if let header {
                        header
                            .padding(.top, 20)
                    }

                    if showCategoryRow {
                        categoryRow(proxy: proxy)
                            .padding(.top, header == nil ? 20 : 0)
                    }

                    ForEach(categories) { category in
                        shelf(for: category)
                            .id(category.id)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }

    private func categoryRow(proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(categories) { category in
                    Button {
                        withAnimation { proxy.scrollTo(category.id, anchor: .top) }
                    } label: {
                        Text(category.name.uppercased())
                            .font(.brunoBody(20, weight: .semibold))
                            .tracking(2)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.card)
                }
            }
            .padding(.horizontal, 50)
        }
        .focusSection()
    }

    private func shelf(for category: BrunoCollectionCategory) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(eyebrow.uppercased())
                        .font(.brunoBody(20, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(Color.bruno.accent)

                    Text(category.name)
                        .font(.brunoDisplay(36, weight: .semibold))
                        .foregroundStyle(Color.bruno.fg)
                }

                Spacer()

                if category.drillStyle != .grid || category.children.count > shelfCap {
                    showAllButton(for: category)
                }
            }
            .padding(.horizontal, 50)

            PosterHStack(
                title: nil,
                // Big portrait cards (like the old Collections grid), not landscape.
                type: .portrait,
                items: Array(category.children.prefix(shelfCap))
            ) { item in
                router.route(to: .item(item: item))
            }
        }
    }

    private func showAllButton(for category: BrunoCollectionCategory) -> some View {
        Button {
            switch category.drillStyle {
            case .genres:
                router.route(to: .brunoGenres(parent: category.boxSet, core: nil))
            case .shelves:
                router.route(to: .brunoCategoryShelves(parent: category.boxSet), in: namespace)
            case .items:
                router.route(to: .brunoItemsGrid(title: category.name, items: category.children), in: namespace)
            case .grid:
                if category.boxSet.libraryType == .boxSet {
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
        } label: {
            Label("Show all", systemImage: "chevron.right")
                .font(.brunoBody(20, weight: .semibold))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
        }
        .buttonStyle(.card)
        // Source for the route's zoom transition, matching the stock library convention.
        // Via .backport so it no-ops below tvOS 18 instead of failing to compile.
        .backport
        .matchedTransitionSource(id: "item", in: namespace)
    }
}
