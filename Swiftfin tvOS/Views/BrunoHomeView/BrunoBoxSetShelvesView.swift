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
                    eyebrow: lensEyebrow,
                    featured: brunoFeaturedItem(in: viewModel.categories),
                    heroEyebrow: "Featured Film"
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onFirstAppear {
            Task { await viewModel.load(parent: parent) }
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

    func load(parent: BaseItemDto) async {
        guard let userSession, let parentID = parent.id else {
            isLoading = false
            return
        }

        let client = userSession.client
        let userID = userSession.user.id

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
                let fetch = perShelfFetch
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
                guard children.isNotEmpty else { continue }
                indexed.append((index, BrunoCollectionCategory(boxSet: subGroup, children: children)))
            }
        }

        categories = indexed
            .sorted { $0.0 < $1.0 }
            .map(\.1)
        isLoading = false
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
        parameters.fields = .MinimumFields
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
