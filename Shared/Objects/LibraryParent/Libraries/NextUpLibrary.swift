//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

struct NextUpLibrary: PagingLibrary {

    let parent: _TitledLibraryParent

    init() {
        self.parent = _TitledLibraryParent(
            displayTitle: L10n.nextUp,
            libraryID: "next-up",
        )
    }

    func retrievePage(
        environment: Void,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetNextUpParameters()
        parameters.enableRewatching = Defaults[.Customization.Home.resumeNextUp]
        parameters.enableUserData = true

        let maxNextUp = Defaults[.Customization.Home.maxNextUp]
        if maxNextUp > 0 {
            parameters.nextUpDateCutoff = Date.now.addingTimeInterval(-maxNextUp)
        }

        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset

        let request = Paths.getNextUp(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
