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
                BrunoCategoryShelves(categories: viewModel.categories, eyebrow: "Collection")
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
        default: .grid // flat full grid (§3)
        }
    }

    func load() async {
        guard let userSession else {
            isLoading = false
            return
        }

        let client = userSession.client
        let userID = userSession.user.id
        let snapshot = await BrunoLibrarySnapshot.load(client: client, userID: userID)

        // Same curated groups the home spine derives from, in server order; drop empties.
        var built = snapshot.favoriteGroupBoxSets.compactMap { boxSet -> BrunoCollectionCategory? in
            guard let name = boxSet.name else { return nil }
            let children = snapshot.childrenByGroupName[name] ?? []
            guard children.isNotEmpty else { return nil }
            return BrunoCollectionCategory(
                boxSet: boxSet,
                children: children,
                drillStyle: Self.drillStyle(for: name)
            )
        }

        // Boxed Sets: every box set NOT already surfaced by a curated group (or as a group child),
        // i.e. the standalone franchise collections.
        let groupIDs = Set(snapshot.favoriteGroupBoxSets.compactMap(\.id))
        let childIDs = Set(snapshot.childrenByGroupName.values.flatMap(\.self).compactMap(\.id))
        let franchiseBoxSets = await Self.fetchAllBoxSets(client: client, userID: userID)
            .filter { boxSet in
                guard let id = boxSet.id else { return false }
                return !groupIDs.contains(id) && !childIDs.contains(id)
            }
        if franchiseBoxSets.isNotEmpty {
            built.append(
                BrunoCollectionCategory(
                    boxSet: BaseItemDto(name: "Boxed Sets"),
                    children: franchiseBoxSets,
                    drillStyle: .items
                )
            )
        }

        categories = built
        isLoading = false
    }

    private nonisolated static func fetchAllBoxSets(client: JellyfinClient, userID: String) async -> [BaseItemDto] {
        var parameters = Paths.GetItemsParameters()
        parameters.userID = userID
        parameters.isRecursive = true
        parameters.includeItemTypes = [.boxSet]
        parameters.fields = .MinimumFields
        parameters.enableUserData = true
        parameters.sortBy = [.name]
        parameters.sortOrder = [.ascending]
        parameters.limit = 200
        do {
            let response = try await client.send(Paths.getItems(parameters: parameters))
            return response.value.items ?? []
        } catch {
            return []
        }
    }
}
