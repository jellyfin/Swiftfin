//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct NextUpLibrary: PagingLibrary {

    struct Environment: WithDefaultValue {
        let enableRewatching: Bool
        let maxNextUp: TimeInterval

        static var `default`: Self {
            .init(
                enableRewatching: false,
                maxNextUp: 0
            )
        }
    }

    let parent: _TitledLibraryParent

    init() {
        self.parent = _TitledLibraryParent(
            displayTitle: L10n.nextUp,
            libraryID: "next-up",
        )
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetNextUpParameters()
        parameters.enableRewatching = environment.enableRewatching
        parameters.enableUserData = true

        if environment.maxNextUp > 0 {
            parameters.nextUpDateCutoff = Date.now.addingTimeInterval(-environment.maxNextUp)
        }

        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset

        let request = Paths.getNextUp(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
