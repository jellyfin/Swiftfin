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

// MARK: - BrunoBoxSetShelvesView (tvOS only)

//
// Drill-in for a single group BoxSet (Genres or Decades): a shelf per child sub-group (each
// genre / each decade), capped, with "Show all" -> the full grid for that sub-group (roadmap §4).
// Mirrors the Collections hub exactly via the shared BrunoCategoryShelves.
struct BrunoBoxSetShelvesView: View {

    let parent: BaseItemDto

    @StateObject
    private var viewModel = BrunoBoxSetShelvesViewModel()

    /// Decades only: the active decade filter (mirrors the Genres core panel). In-place, no refetch.
    @State
    private var selectedDecade: String?

    private var isDecades: Bool {
        parent.displayTitle.lowercased() == "decades"
    }

    /// Decades use a pill selector that filters to one decade; everything else shows all shelves.
    private var shownCategories: [BrunoCollectionCategory] {
        guard isDecades, let selectedDecade else { return viewModel.categories }
        return viewModel.categories.filter { $0.name == selectedDecade }
    }

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
                // Decades mirror the Genres page: a pill row instead of the big decade cards,
                // switching the shown decade in place. Other groups (Curated) keep the card row.
                BrunoCategoryShelves(
                    categories: shownCategories,
                    eyebrow: lensEyebrow,
                    header: isDecades ? AnyView(decadePanel) : nil,
                    showCategoryRow: !isDecades,
                    featured: brunoFeaturedItem(in: shownCategories),
                    heroEyebrow: "Featured Film",
                    // Decade surface opts in to per-poster release dates; Genres/Curated keep the default.
                    showsDate: isDecades
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onFirstAppear {
            Task { await viewModel.load(parent: parent) }
        }
    }

    private var decadePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Decade".uppercased())
                .font(.brunoBody(20, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Color.bruno.accent)
                .padding(.horizontal, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(viewModel.categories) { category in
                        BrunoSelectorCard(
                            title: category.name,
                            isSelected: selectedDecade == category.name
                        ) {
                            selectedDecade = selectedDecade == category.name ? nil : category.name
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 8)
            }
            .focusSection()
        }
    }

    /// Singularised group name ("Genres" -> "Genre", "Decades" -> "Decade").
    private var eyebrow: String {
        let name = parent.displayTitle
        return name.count > 1 && name.hasSuffix("s") ? String(name.dropLast()) : name
    }

    /// Lens-style shelf eyebrow per surface (mockup lens system); falls back to the singular name.
    private var lensEyebrow: String {
        switch parent.displayTitle.lowercased() {
        case "decades": "Browse by Decade"
        case "curated": "Curated"
        default: eyebrow
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("Nothing here yet")
                .font(.brunoDisplay(40, weight: .semibold))
                .foregroundStyle(Color.bruno.fg)
            Text("This collection has no sub-categories to show.")
                .font(.brunoBody(22))
                .foregroundStyle(Color.bruno.fgMuted)
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - BrunoBoxSetShelvesViewModel

@MainActor
final class BrunoBoxSetShelvesViewModel: ViewModel {

    @Published
    private(set) var categories: [BrunoCollectionCategory] = []
    @Published
    private(set) var isLoading = true

    /// One past the shelf cap so the shared scaffold can tell whether "Show all" is warranted.
    private let perShelfFetch = 13

    /// Day-stable seed for shelf shuffling — same order all day, reshuffles the next day.
    private static var shuffleSeed: UInt32 {
        UInt32(truncatingIfNeeded: Int(Date().timeIntervalSince1970 / 86400))
    }

    func load(parent: BaseItemDto) async {
        guard let userSession, let parentID = parent.id else {
            isLoading = false
            return
        }

        let client = userSession.client
        let userID = userSession.user.id

        // Genre rows are biased to modern films (owner request): pre-1985 titles are dropped from the
        // "If You Like {genre}" shelves and the same film can't fill two overlapping genre rows. They
        // still appear in each genre's full "Show all" grid (sunk to the bottom). Decades / Curated /
        // any other group are NOT biased — they exist precisely to surface older eras. We fetch a
        // deeper page when biased so enough modern titles survive the filter to fill a preview row.
        let recencyBiased = parent.displayTitle.lowercased() == "genres"
        let childFetch = recencyBiased ? 60 : perShelfFetch

        let subGroups = await Self.fetchChildren(
            client: client,
            userID: userID,
            parentID: parentID,
            limit: 100
        )

        // Fetch each sub-group's children concurrently; preserve server order via the index.
        var indexed: [(Int, BrunoCollectionCategory)] = []
        await withTaskGroup(of: (Int, BaseItemDto, [BaseItemDto]).self) { group in
            for (index, subGroup) in subGroups.enumerated() {
                guard let subID = subGroup.id else { continue }
                let fetch = childFetch
                group.addTask {
                    let children = await Self.fetchChildren(
                        client: client,
                        userID: userID,
                        parentID: subID,
                        limit: fetch
                    )
                    return (index, subGroup, children)
                }
            }

            for await (index, subGroup, children) in group {
                let modern = recencyBiased ? BrunoRecencyBias.modernOnly(children) : children
                // Seeded shuffle so shelves read varied rather than alphabetical (owner request).
                // Day-stable seed + per-shelf offset → stable within a day, fresh the next.
                let shown = BrunoRNG.shuffled(modern, seed: Self.shuffleSeed &+ UInt32(truncatingIfNeeded: index))
                guard shown.isNotEmpty else { continue }
                indexed.append((
                    index,
                    BrunoCollectionCategory(boxSet: subGroup, children: shown, recencyBiased: recencyBiased)
                ))
            }
        }

        let baseOrdered = indexed
            .sorted { $0.0 < $1.0 }
            .map(\.1)

        // Decades render newest-first (owner request): sort by leading year descending, which also
        // drops the "1950s & Earlier" catch-all (year 1950, the smallest) to the bottom. Other
        // groups keep server order.
        let isDecades = parent.displayTitle.lowercased() == "decades"
        let ordered = isDecades
            ? baseOrdered.sorted { Self.leadingYear($0.name) > Self.leadingYear($1.name) }
            : baseOrdered

        categories = recencyBiased ? Self.dedupeAcrossCategories(ordered) : ordered
        isLoading = false
    }

    /// The leading numeric year in a decade sub-group name ("2020s" → 2020, "1950s & Earlier" →
    /// 1950); 0 when none, so any non-decade name sorts last under the descending sort.
    private static func leadingYear(_ name: String) -> Int {
        Int(name.prefix { $0.isNumber }) ?? 0
    }

    /// Drop a film from every genre shelf after the first that lists it (server order wins), so the
    /// same title can't fill both "Romantic Comedy" and "Romantic Drama" when the server's genre tags
    /// overlap. A category emptied by the pass is dropped. Duplicates still resurface in each genre's
    /// full "Show all" grid — they're only deduped across the preview rows.
    private static func dedupeAcrossCategories(_ categories: [BrunoCollectionCategory]) -> [BrunoCollectionCategory] {
        var seen: Set<String> = []
        var out: [BrunoCollectionCategory] = []
        for category in categories {
            let fresh = category.children.filter { item in
                guard let id = item.id else { return true }
                return seen.insert(id).inserted
            }
            guard fresh.isNotEmpty else { continue }
            out.append(BrunoCollectionCategory(
                boxSet: category.boxSet,
                children: fresh,
                drillStyle: category.drillStyle,
                lens: category.lens,
                recencyBiased: category.recencyBiased
            ))
        }
        return out
    }

    private nonisolated static func fetchChildren(
        client: JellyfinClient,
        userID: String,
        parentID: String,
        limit: Int
    ) async -> [BaseItemDto] {
        var parameters = Paths.GetItemsParameters()
        parameters.userID = userID
        parameters.parentID = parentID
        // .genres feeds the hero child-safety filter (brunoHeroEligible) on this drill-in's
        // "Featured Film"; MinimumFields omits genres, which would make the filter a no-op.
        parameters.fields = .MinimumFields + [.genres]
        parameters.enableUserData = true
        parameters.limit = limit
        do {
            let response = try await client.send(Paths.getItems(parameters: parameters))
            return response.value.items ?? []
        } catch {
            return []
        }
    }
}

// MARK: - NavigationRoute

extension NavigationRoute {

    @MainActor
    static func brunoCategoryShelves(parent: BaseItemDto) -> NavigationRoute {
        NavigationRoute(
            id: "bruno-shelves-\(parent.id ?? parent.displayTitle)",
            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
        ) {
            BrunoBoxSetShelvesView(parent: parent)
        }
    }
}
