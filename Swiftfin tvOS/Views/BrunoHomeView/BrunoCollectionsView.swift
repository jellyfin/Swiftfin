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

// MARK: - BrunoCollectionsView (tvOS only)

//
// The Collections tab, redesigned from a flat BoxSet grid into per-category shelves (roadmap §3):
// a category row across the top that jumps to each shelf, then one capped horizontal shelf per
// curated group (Directors, Decades, Studios, …). Each shelf header carries a "Show all" that
// routes to the full grid for that group via the stock ItemLibrary -> PagingLibraryView.
struct BrunoCollectionsView: View {

    @StateObject
    private var viewModel = BrunoCollectionsViewModel()

    @Router
    private var router

    @Namespace
    private var namespace

    /// Items shown before the "Show all" card (roadmap §3: single line, ~12).
    private let shelfCap = 12

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .tint(Color.bruno.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.categories.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onFirstAppear {
            Task { await viewModel.load() }
        }
    }

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 36) {
                    categoryRow(proxy: proxy)
                        .padding(.top, 20)

                    ForEach(viewModel.categories) { category in
                        shelf(for: category)
                            .id(category.id)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }

    // MARK: Category row

    private func categoryRow(proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.categories) { category in
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

    // MARK: Shelf

    private func shelf(for category: BrunoCollectionCategory) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Collection".uppercased())
                        .font(.brunoBody(20, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(Color.bruno.accent)

                    Text(category.name)
                        .font(.brunoDisplay(36, weight: .semibold))
                        .foregroundStyle(Color.bruno.fg)
                }

                Spacer()

                if category.children.count > shelfCap {
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
            router.route(
                to: .library(library: ItemLibrary(parent: category.boxSet, filters: .default)),
                in: namespace
            )
        } label: {
            Label("Show all", systemImage: "chevron.right")
                .font(.brunoBody(20, weight: .semibold))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
        }
        .buttonStyle(.card)
        // Source for the .library route's zoom transition, matching the stock library convention.
        .matchedTransitionSource(id: "item", in: namespace)
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No collections yet")
                .font(.brunoDisplay(40, weight: .semibold))
                .foregroundStyle(Color.bruno.fg)
            Text("Curated collections from this server will appear here.")
                .font(.brunoBody(22))
                .foregroundStyle(Color.bruno.fgMuted)
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - BrunoCollectionCategory

//
// One curated group (a favorited BoxSet) plus its child sub-collections.
struct BrunoCollectionCategory: Identifiable {

    let boxSet: BaseItemDto
    let children: [BaseItemDto]

    var id: String {
        boxSet.id ?? boxSet.displayTitle
    }

    var name: String {
        boxSet.displayTitle
    }
}

// MARK: - BrunoCollectionsViewModel

@MainActor
final class BrunoCollectionsViewModel: ViewModel {

    @Published
    private(set) var categories: [BrunoCollectionCategory] = []
    @Published
    private(set) var isLoading = true

    func load() async {
        guard let userSession else {
            isLoading = false
            return
        }

        let snapshot = await BrunoLibrarySnapshot.load(
            client: userSession.client,
            userID: userSession.user.id
        )

        // Same curated groups the home spine derives from, in server order; drop empties.
        categories = snapshot.favoriteGroupBoxSets.compactMap { boxSet in
            guard let name = boxSet.name else { return nil }
            let children = snapshot.childrenByGroupName[name] ?? []
            guard children.isNotEmpty else { return nil }
            return BrunoCollectionCategory(boxSet: boxSet, children: children)
        }

        isLoading = false
    }
}
