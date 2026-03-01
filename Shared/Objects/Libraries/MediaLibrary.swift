//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct MediaLibrary: PagingLibrary {

    let displayTitle: String
    let id: String
    let hasNextPage: Bool = false

    var parent: _TitledLibraryParent

    init() {
        self.displayTitle = L10n.media
        self.id = "media-library"

        self.parent = _TitledLibraryParent(
            displayTitle: L10n.media,
            libraryID: "media-library"
        )
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        let parameters = Paths.GetUserViewsParameters(userID: pageState.userSession.user.id)
        let userViewsPath = Paths.getUserViews(parameters: parameters)
        let userViews = try await pageState.userSession.client.send(userViewsPath)
        let excludedLibraryIDs = pageState.userSession.user.data.configuration?.latestItemsExcludes ?? []

        return (userViews.value.items ?? [])
            .coalesced(property: \.collectionType, with: .folders)
            .intersecting(CollectionType.supportedCases, using: \.collectionType)
            .subtracting(excludedLibraryIDs, using: \.id)
    }
}
