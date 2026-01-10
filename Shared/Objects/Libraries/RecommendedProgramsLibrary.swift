//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct RecommendedProgramsLibrary: PagingLibrary {

    let parent: _TitledLibraryParent

    init() {
        self.parent = _TitledLibraryParent(
            displayTitle: L10n.onNow,
            libraryID: "programs-recommended"
        )
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetRecommendedProgramsParameters()
        parameters.fields = [.channelInfo]
        parameters.isAiring = true
        parameters.limit = pageState.pageSize
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getRecommendedPrograms(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
