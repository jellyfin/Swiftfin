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
// a category row across the top, then one capped shelf per curated group (Directors, Decades,
// Studios, …). Genres/Decades "Show all" drills into a further shelf-per-sub-group view (§4);
// the rest open the stock full grid. Rendering is delegated to the shared BrunoCategoryShelves.
struct BrunoCollectionsView: View {

    @StateObject
    private var viewModel = BrunoCollectionsViewModel()

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
                BrunoCategoryShelves(
                    categories: viewModel.categories,
                    eyebrow: "Browse the Library",
                    featured: brunoFeaturedItem(in: viewModel.categories),
                    heroEyebrow: "Featured"
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onFirstAppear {
            Task { await viewModel.load() }
        }
    }

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

// MARK: - BrunoCollectionsViewModel

@MainActor
final class BrunoCollectionsViewModel: ViewModel {

    @Published
    private(set) var categories: [BrunoCollectionCategory] = []
    @Published
    private(set) var isLoading = true

    private static func drillStyle(for groupName: String) -> BrunoCollectionCategory.DrillStyle {
        switch groupName.lowercased() {
        case "genres": .genres // core-category panel + mixed sub-genre shelves (§4 + core panel)
        case "decades": .shelves // shelf per decade (§4)
        case "curated": .shelves // shelf per curated sub-collection (Asian Cinema, Oscar Buzz, …)
        default: .grid // flat full grid (§3)
        }
    }

    /// Per-category lens eyebrow so each Collections shelf reads with its own flavor instead of a
    /// flat repeated "Browse the Library" (matches Home's lens variety). nil → surface default.
    private static func lens(for groupName: String) -> String? {
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

    func load() async {
        guard let userSession else {
            isLoading = false
            return
        }

        let client = userSession.client
        let userID = userSession.user.id
        // Reuse the snapshot Home just loaded (shared cache) instead of refetching the whole
        // library on every Home -> Collections navigation.
        let snapshot = await BrunoLibrarySnapshot.loadShared(client: client, userID: userID)

        // Same curated groups the home spine derives from, in server order; drop empties.
        var built = snapshot.favoriteGroupBoxSets.compactMap { boxSet -> BrunoCollectionCategory? in
            guard let name = boxSet.name else { return nil }
            let children = snapshot.childrenByGroupName[name] ?? []
            guard children.isNotEmpty else { return nil }
            return BrunoCollectionCategory(
                boxSet: boxSet,
                children: children,
                drillStyle: Self.drillStyle(for: name),
                lens: Self.lens(for: name)
            )
        }

        // Boxed Sets: every box set NOT already surfaced by a curated group (or as a group child),
        // i.e. the standalone franchise collections. Director collections (e.g. "Joel Coen",
        // "Ethan Coen") belong to the Directors section — exclude any standalone box set whose name
        // matches a Directors-group child (the id-exclusion below already drops director collections
        // that ARE nested under Directors; this catches name-identical standalone duplicates). A
        // genuinely orphan director collection — one that is neither nested nor name-matched — is a
        // server-curation gap (add it under Directors); the DEBUG log below surfaces strays.
        let groupIDs = Set(snapshot.favoriteGroupBoxSets.compactMap(\.id))
        let childIDs = Set(snapshot.childrenByGroupName.values.flatMap(\.self).compactMap(\.id))
        let directorNames = Set(snapshot.directorBoxSets.compactMap { $0.name?.trimmedLowercased })
        let franchiseBoxSets = await Self.fetchAllBoxSets(client: client, userID: userID)
            .filter { boxSet in
                guard let id = boxSet.id else { return false }
                guard !groupIDs.contains(id), !childIDs.contains(id) else { return false }
                if let name = boxSet.name?.trimmedLowercased, directorNames.contains(name) { return false }
                return true
            }
        if franchiseBoxSets.isNotEmpty {
            built.append(
                BrunoCollectionCategory(
                    boxSet: BaseItemDto(name: "Boxed Sets"),
                    children: franchiseBoxSets,
                    drillStyle: .items,
                    lens: "Franchises"
                )
            )
            #if DEBUG
            print("[Bruno] Boxed Sets (\(franchiseBoxSets.count)): \(franchiseBoxSets.compactMap(\.name).sorted())")
            #endif
        }

        // Fixed top-shelf order (owner request). Explicit rank by group name; unknown names fall to
        // the end in server order. Decorate-with-index so the sort is stable independent of the
        // standard library's (unspecified) sort stability. Reordering doesn't change any category's
        // id, so focus identity holds.
        let rank: [String: Int] = [
            "new releases": 0, "genres": 1, "directors": 2, "boxed sets": 3,
            "decades": 4, "curated": 5, "studios": 6, "seasonal": 7,
        ]
        categories = built.enumerated()
            .sorted { lhs, rhs in
                let l = rank[lhs.element.name.lowercased()] ?? .max
                let r = rank[rhs.element.name.lowercased()] ?? .max
                return l != r ? l < r : lhs.offset < rhs.offset
            }
            .map(\.element)
        isLoading = false
    }

    private nonisolated static func fetchAllBoxSets(client: JellyfinClient, userID: String) async -> [BaseItemDto] {
        var parameters = Paths.GetItemsParameters()
        parameters.userID = userID
        parameters.isRecursive = true
        parameters.includeItemTypes = [.boxSet]
        // .childCount feeds the "N films" line on the landscape collection cards; it is NOT in
        // MinimumFields, so without this the count is nil and that line is hidden.
        parameters.fields = .MinimumFields + [.childCount]
        parameters.enableUserData = true
        parameters.sortBy = [.name]
        parameters.sortOrder = [.ascending]
        // The library has 300+ box sets; a 200 cap (sorted by name) silently dropped late-alphabet
        // franchises (Star Wars, The Lord of the Rings, …). Fetch them all.
        parameters.limit = 1000
        do {
            let response = try await client.send(Paths.getItems(parameters: parameters))
            return response.value.items ?? []
        } catch {
            return []
        }
    }
}
