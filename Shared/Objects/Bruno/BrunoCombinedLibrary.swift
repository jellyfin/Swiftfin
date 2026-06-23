//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

// MARK: - BrunoCombinedLibrary

//
// A `PagingLibrary` that presents the merged contents of several parent libraries as a
// single grid. Used by the Bruno **Kids** tab, whose content the owner split across separate
// Jellyfin libraries (e.g. "Kids Movies" + "Kids Shows") rather than one "Kids" user view —
// so a single `ItemLibrary(parent:)` can't show it all.
//
// Each parent is fetched recursively (one request per parent), then the results are
// de-duplicated by id and sorted by title. This is a single-page library (no pagination):
// kids libraries are small, and merging server pages across multiple parents can't preserve
// a stable global offset. Mirrors `UserViewLibrary`'s page-0-only contract.
struct BrunoCombinedLibrary: BaseItemKindLibrary {

    let parents: [BaseItemDto]
    let parent: TitledLibraryParent
    let itemTypes: [BaseItemKind]
    let hasNextPage: Bool = false

    /// Cap per parent — high enough for a real kids library, bounded so one page stays cheap.
    private let perParentLimit = 400

    var libraryItemTypes: [BaseItemKind] {
        itemTypes
    }

    init(
        parents: [BaseItemDto],
        title: String,
        id: String,
        itemTypes: [BaseItemKind]
    ) {
        self.parents = parents
        self.itemTypes = itemTypes
        self.parent = .init(displayTitle: title, id: id)
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        guard pageState.pageOffset == 0 else { return [] }

        let session = pageState.userSession
        let parentIDs = parents.compactMap(\.id)

        // Sequential rather than concurrent: only a handful of parents, and it keeps the
        // request on the library's MainActor without UserSession Sendable gymnastics.
        var merged: [BaseItemDto] = []
        for parentID in parentIDs {
            var parameters = Paths.GetItemsParameters()
            parameters.userID = session.user.id
            parameters.parentID = parentID
            parameters.isRecursive = true
            parameters.includeItemTypes = itemTypes
            parameters.enableUserData = true
            parameters.fields = .MinimumFields
            parameters.sortBy = [.name]
            parameters.sortOrder = [.ascending]
            parameters.limit = perParentLimit

            let request = Paths.getItems(parameters: parameters)
            let response = try await session.client.send(request)
            merged.append(contentsOf: response.value.items ?? [])
        }

        var seen = Set<String>()
        let deduped = merged.filter { item in
            guard let id = item.id else { return true }
            return seen.insert(id).inserted
        }

        return deduped.sorted {
            $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
        }
    }
}
