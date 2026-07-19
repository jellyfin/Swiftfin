//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct LatestInLibrary: BaseItemKindLibrary {

    let includedItemTypes: [BaseItemKind]?
    let libraryItemTypes: [BaseItemKind]
    let parent: TitledLibraryParent

    init(library: BaseItemDto) {
        self.parent = .init(
            displayTitle: L10n.latestWithString(library.displayTitle),
            id: library.id
        )
        #if os(iOS)
        self.includedItemTypes = library.collectionType == .music ? [.musicAlbum] : nil
        #else
        self.includedItemTypes = nil
        #endif
        self.libraryItemTypes = library.supportedItemTypes
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetLatestMediaParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = includedItemTypes
        parameters.limit = pageState.pageSize
        parameters.parentID = parent.id
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getLatestMedia(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value
    }
}
