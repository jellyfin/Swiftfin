//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

struct NextUpLibrary: PagingLibrary {

    struct Environment: WithDefaultValue {
        var enableRewatching: Bool
        var maxNextUp: TimeInterval

        static let `default`: Self = .init(
            enableRewatching: Defaults[.Customization.Home.resumeNextUp],
            maxNextUp: Defaults[.Customization.Home.maxNextUp]
        )
    }

    let parent: TitledLibraryParent = .init(displayTitle: L10n.nextUp, id: "next-up")

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetNextUpParameters()
        parameters.enableRewatching = environment.enableRewatching
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset

        if environment.maxNextUp > 0 {
            parameters.nextUpDateCutoff = Date.now.addingTimeInterval(-environment.maxNextUp)
        }

        let request = Paths.getNextUp(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
