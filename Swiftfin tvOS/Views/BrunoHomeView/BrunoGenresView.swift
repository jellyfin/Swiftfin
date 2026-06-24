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

// MARK: - BrunoCoreGenre

//
// A curated "core" genre bucket shown as the first line of the Genres page. Each maps to several
// fine-grain server genres by keyword, so it works without hardcoding the server's exact genre
// names. Selecting one opens a page of only that bucket's fine-grain genre shelves.
struct BrunoCoreGenre: Identifiable, Hashable {

    let id: String
    let title: String
    let keywords: [String]

    /// Does a fine-grain server genre (e.g. "Science Fiction", "Adventure") belong to this bucket?
    func matches(_ genreName: String) -> Bool {
        let lowered = genreName.lowercased()
        return keywords.contains { lowered.contains($0) }
    }

    static let all: [BrunoCoreGenre] = [
        .init(id: "action", title: "Action", keywords: ["action", "adventure", "martial", "war", "western", "spy"]),
        .init(
            id: "scifi-fantasy",
            title: "Sci-Fi & Fantasy",
            keywords: ["sci-fi", "scifi", "science fiction", "fantasy", "superhero", "supernatural"]
        ),
        .init(id: "romance", title: "Romance", keywords: ["romance", "romantic"]),
        .init(id: "comedy", title: "Comedy", keywords: ["comedy", "comedies", "sitcom", "stand-up"]),
        .init(id: "drama", title: "Drama", keywords: ["drama"]),
    ]
}

// MARK: - BrunoGenresView (tvOS only)

//
// The Genres page (roadmap §4 + core panel). With `core == nil`: a core-category panel as the
// first line (Action · Sci-Fi & Fantasy · Romance · Comedy · Drama), then the mixed-together
// sub-genre shelves. With a `core` set: only the fine-grain genre shelves in that bucket.
struct BrunoGenresView: View {

    let parent: BaseItemDto
    let core: BrunoCoreGenre?

    @StateObject
    private var viewModel = BrunoBoxSetShelvesViewModel()

    @Router
    private var router

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .tint(Color.bruno.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if shownCategories.isEmpty {
                emptyState
            } else {
                BrunoCategoryShelves(
                    categories: shownCategories,
                    eyebrow: "If You Like",
                    header: AnyView(header),
                    // Main page leads with the core panel; a core sub-page keeps the chip row.
                    showCategoryRow: core != nil,
                    featured: brunoFeaturedItem(in: shownCategories),
                    heroEyebrow: core.map { "\($0.title) Pick" } ?? "Featured Film"
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onFirstAppear {
            Task { await viewModel.load(parent: parent) }
        }
    }

    /// All fine-grain genres on the main page; only the bucket's genres on a core sub-page.
    private var shownCategories: [BrunoCollectionCategory] {
        guard let core else { return viewModel.categories }
        return viewModel.categories.filter { core.matches($0.name) }
    }

    @ViewBuilder
    private var header: some View {
        if let core {
            Text(core.title)
                .font(.brunoDisplay(56, weight: .bold))
                .foregroundStyle(Color.bruno.fg)
                .padding(.horizontal, 50)
        } else {
            corePanel
        }
    }

    private var corePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by".uppercased())
                .font(.brunoBody(20, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Color.bruno.accent)
                .padding(.horizontal, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(BrunoCoreGenre.all) { coreGenre in
                        BrunoSelectorCard(title: coreGenre.title) {
                            router.route(to: .brunoGenres(parent: parent, core: coreGenre))
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 8)
            }
            .focusSection()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text(core == nil ? "No genres yet" : "Nothing in \(core?.title ?? "")")
                .font(.brunoDisplay(40, weight: .semibold))
                .foregroundStyle(Color.bruno.fg)
            Text("Genres from this server will appear here.")
                .font(.brunoBody(22))
                .foregroundStyle(Color.bruno.fgMuted)
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - NavigationRoute

extension NavigationRoute {

    @MainActor
    static func brunoGenres(parent: BaseItemDto, core: BrunoCoreGenre?) -> NavigationRoute {
        NavigationRoute(
            id: "bruno-genres-\(parent.id ?? parent.displayTitle)-\(core?.id ?? "all")"
        ) {
            BrunoGenresView(parent: parent, core: core)
        }
    }
}
