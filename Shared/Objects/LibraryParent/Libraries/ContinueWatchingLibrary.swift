//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct ContinueWatchingLibrary: PagingLibrary {

    let parent: _TitledLibraryParent

    init() {
        self.parent = _TitledLibraryParent(
            displayTitle: "Continue Watching",
            libraryID: "continue-watching",
        )
    }

    func retrievePage(
        environment: Void,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetResumeItemsParameters()
        parameters.userID = pageState.userSession.user.id
        parameters.enableUserData = true
        parameters.mediaTypes = [.video]
        parameters.limit = 20

        let request = Paths.getResumeItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
