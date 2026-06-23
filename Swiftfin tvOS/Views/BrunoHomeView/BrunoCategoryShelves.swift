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

    let boxSet: BaseItemDto
    let children: [BaseItemDto]
    /// When true, "Show all" drills into a further shelf-per-sub-group view (Genres/Decades);
    /// otherwise it opens the flat full grid for this group (roadmap §3/§4).
    let showAllAsShelves: Bool

    init(boxSet: BaseItemDto, children: [BaseItemDto], showAllAsShelves: Bool = false) {
        self.boxSet = boxSet
        self.children = children
        self.showAllAsShelves = showAllAsShelves
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
                    categoryRow(proxy: proxy)
                        .padding(.top, 20)

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

                if category.showAllAsShelves || category.children.count > shelfCap {
                    showAllButton(for: category)
                }
            }
            .padding(.horizontal, 50)

            PosterHStack(
                title: nil,
                type: .landscape,
                items: Array(category.children.prefix(shelfCap))
            ) { item in
                router.route(to: .item(item: item))
            }
        }
    }

    private func showAllButton(for category: BrunoCollectionCategory) -> some View {
        Button {
            if category.showAllAsShelves {
                router.route(to: .brunoCategoryShelves(parent: category.boxSet), in: namespace)
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
        } label: {
            Label("Show all", systemImage: "chevron.right")
                .font(.brunoBody(20, weight: .semibold))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
        }
        .buttonStyle(.card)
        // Source for the route's zoom transition, matching the stock library convention.
        .matchedTransitionSource(id: "item", in: namespace)
    }
}
