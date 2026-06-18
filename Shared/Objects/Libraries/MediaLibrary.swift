//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct MediaLibrary: BaseItemKindLibrary {

    let hasNextPage: Bool = false
    let libraryItemTypes: [BaseItemKind] = [.userView]
    let parent: TitledLibraryParent = .init(displayTitle: L10n.media, id: "media-library")

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        let parameters = Paths.GetUserViewsParameters(userID: pageState.userSession.user.id)
        let request = Paths.getUserViews(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)
        let excludedLibraryIDs = pageState.userSession.user.data.configuration?.latestItemsExcludes ?? []

        return (response.value.items ?? [])
            .coalesced(property: \.collectionType, with: .folders)
            .intersecting(CollectionType.supportedCases, using: \.collectionType)
            .subtracting(excludedLibraryIDs, using: \.id)
    }
}
