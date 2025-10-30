//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct LatestInLibrary: PagingLibrary {

    let parent: _TitledLibraryParent

    init(library: BaseItemDto) {
        self.parent = _TitledLibraryParent(
            displayTitle: L10n.latestWithString(library.displayTitle),
            libraryID: library.libraryID
        )
    }

    func retrievePage(
        environment: VoidWithDefaultValue,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetLatestMediaParameters()
        parameters.userID = pageState.userSession.user.id
        parameters.parentID = parent.libraryID
        parameters.enableUserData = true
        parameters.limit = pageState.pageSize

        let request = Paths.getLatestMedia(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)
        return response.value
    }
}
