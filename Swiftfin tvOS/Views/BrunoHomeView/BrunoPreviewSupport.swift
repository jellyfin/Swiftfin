//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if DEBUG
import JellyfinAPI
import SwiftUI

// Prototype copy is English-only; localization (L10n) is a deferred TODO (see BRUNO_NOTES.md).
// swiftlint:disable hard_coded_display_string

// MARK: - Bruno preview / snapshot support (DEBUG only)

//
// Mock `BaseItemDto`s + a self-contained gallery so the Bruno GUI can be rendered with NO
// server, NO sign-in and NO keychain — sidestepping the (stock, signing-related) post-login
// keychain assertion entirely. Mock items carry no image tags/session, so posters fall back
// to their stock placeholder (system glyph + title) and the hero shows its branded text over
// the dark page: layout, focus, fonts (Oswald/Inter) and the accent palette all render.
//
// Driven at launch by `SwiftfinApp` when the `BRUNO_SNAPSHOT` env var is set (see that file);
// `BRUNO_SNAPSHOT_VIEW` picks which surface to show so each can be screenshotted on the sim:
//   home  → header + hero + shelves in the real `ScrollView`/`LazyVStack` (default)
//   hero  → just `BrunoHeroView`
//   shelf → a stack of `BrunoShelfView`s
enum BrunoMock {

    static func item(
        _ id: String,
        _ name: String,
        year: Int,
        rating: Float? = nil,
        genre: String? = nil,
        rated: String? = nil,
        overview: String? = nil,
        type: BaseItemKind = .movie
    ) -> BaseItemDto {
        BaseItemDto(
            communityRating: rating,
            genres: genre.map { [$0] },
            id: id,
            name: name,
            officialRating: rated,
            overview: overview,
            productionYear: year,
            type: type
        )
    }

    /// The rotating 5-item spotlight pool for `BrunoHeroView`.
    static let heroItems: [BaseItemDto] = [
        item(
            "h1",
            "Blade Runner",
            year: 1982,
            rating: 8.1,
            genre: "Sci-Fi",
            rated: "R",
            overview: "A blade runner must pursue and terminate four replicants who stole a ship in space and have returned to Earth to find their creator."
        ),
        item("h2", "Chungking Express", year: 1994, rating: 8.0, genre: "Drama", rated: "PG-13"),
        item("h3", "Whiplash", year: 2014, rating: 8.5, genre: "Drama", rated: "R"),
        item("h4", "Mad Max: Fury Road", year: 2015, rating: 8.1, genre: "Action", rated: "R"),
        item("h5", "Spirited Away", year: 2001, rating: 8.6, genre: "Animation", rated: "PG"),
    ]

    private static let titles: [(String, Int, Float, String)] = [
        ("Heat", 1995, 8.3, "Crime"),
        ("The Thing", 1982, 8.2, "Horror"),
        ("Paris, Texas", 1984, 8.1, "Drama"),
        ("Akira", 1988, 8.0, "Animation"),
        ("Drive", 2011, 7.8, "Crime"),
        ("Arrival", 2016, 7.9, "Sci-Fi"),
        ("No Country for Old Men", 2007, 8.2, "Thriller"),
        ("In the Mood for Love", 2000, 8.1, "Romance"),
        ("There Will Be Blood", 2007, 8.2, "Drama"),
        ("Parasite", 2019, 8.5, "Thriller"),
        ("Sicario", 2015, 7.6, "Thriller"),
        ("The Grand Budapest Hotel", 2014, 8.1, "Comedy"),
    ]

    /// A row of mock items, deterministically rotated by `offset` so adjacent shelves differ.
    static func shelfItems(offset: Int, count: Int = 10) -> [BaseItemDto] {
        (0 ..< count).map { i in
            let (name, year, rating, genre) = titles[(offset + i) % titles.count]
            return item("s\(offset)-\(i)", name, year: year, rating: rating, genre: genre)
        }
    }

    /// Realised shelf view models (the `.items` source loads synchronously in `load()`).
    @MainActor
    static func shelf(
        id: String,
        lens: String,
        title: String,
        type: PosterDisplayType,
        offset: Int
    ) -> BrunoShelfViewModel {
        BrunoShelfViewModel(
            shelf: BrunoShelf(
                id: id,
                lens: lens,
                title: title,
                posterType: type,
                kind: .curated,
                dedupeKey: id,
                source: .items(shelfItems(offset: offset))
            )
        )
    }
}

// MARK: - BrunoSnapshotModel

@MainActor
final class BrunoSnapshotModel: ObservableObject {

    @Published
    private(set) var shelves: [BrunoShelfViewModel] = []

    func load() async {
        let descriptors: [BrunoShelfViewModel] = [
            BrunoMock.shelf(id: "resume", lens: "Pick up where you left off", title: "Continue Watching", type: .landscape, offset: 0),
            BrunoMock.shelf(id: "auteurs", lens: "Director Spotlight", title: "Akira Kurosawa", type: .portrait, offset: 3),
            BrunoMock.shelf(id: "decade", lens: "Decade", title: "The 1980s", type: .portrait, offset: 6),
            BrunoMock.shelf(id: "genre", lens: "Genre", title: "Neo-Noir", type: .landscape, offset: 9),
            BrunoMock.shelf(id: "acclaimed", lens: "Critically Acclaimed", title: "Highly Rated", type: .portrait, offset: 1),
        ]
        for descriptor in descriptors {
            await descriptor.load()
        }
        shelves = descriptors
    }
}

// MARK: - BrunoSnapshotGallery

struct BrunoSnapshotGallery: View {

    @StateObject
    private var model = BrunoSnapshotModel()

    @State
    private var heroIndex = 0

    private var surface: String {
        ProcessInfo.processInfo.environment["BRUNO_SNAPSHOT_VIEW"] ?? "home"
    }

    var body: some View {
        ZStack {
            BrunoAmbientBackground(item: BrunoMock.heroItems[safe: heroIndex])

            switch surface {
            case "hero":
                BrunoHeroView(items: BrunoMock.heroItems, index: $heroIndex)
            case "shelf":
                VStack(alignment: .leading, spacing: 40) {
                    ForEach(model.shelves.prefix(2)) { shelf in
                        BrunoShelfView(viewModel: shelf)
                    }
                }
            default:
                home
            }
        }
        .ignoresSafeArea()
        .task { await model.load() }
    }

    private var home: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 36) {
                header
                    .padding(.horizontal, 50)
                    .padding(.top, 20)

                BrunoHeroView(items: BrunoMock.heroItems, index: $heroIndex)

                ForEach(model.shelves) { shelf in
                    BrunoShelfView(viewModel: shelf)
                }
            }
            .padding(.bottom, 60)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                Text("BRUNO")
                    .font(.brunoDisplay(40, weight: .bold))
                    .tracking(6)
                    .foregroundStyle(Color.bruno.fg)
                Circle()
                    .fill(Color.bruno.accent)
                    .frame(width: 12, height: 12)
            }
            Spacer()
            Label("Shuffle", systemImage: "shuffle")
                .font(.brunoBody(22, weight: .semibold))
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.bruno.fgSubtle.opacity(0.3))
                )
        }
    }
}

// MARK: - Previews

#Preview("Bruno Hero") {
    BrunoHeroView(items: BrunoMock.heroItems, index: .constant(0))
        .background(Color.bruno.page)
}

#Preview("Bruno Shelf") {
    let viewModel = BrunoMock.shelf(
        id: "preview-shelf",
        lens: "Director Spotlight",
        title: "Akira Kurosawa",
        type: .portrait,
        offset: 3
    )
    return BrunoShelfView(viewModel: viewModel)
        .background(Color.bruno.page)
        .task { await viewModel.load() }
}

#Preview("Bruno Home") {
    BrunoSnapshotGallery()
}

// swiftlint:enable hard_coded_display_string
#endif
