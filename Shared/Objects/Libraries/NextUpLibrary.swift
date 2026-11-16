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

struct NextUpLibrary: BaseItemKindLibrary {

    struct Environment: WithDefaultValue {

        var enableRewatching: Bool
        var maxNextUp: TimeInterval

        static var `default`: Self {
            .init(
                enableRewatching: Defaults[.Customization.Home.resumeNextUp],
                maxNextUp: Defaults[.Customization.Home.maxNextUp]
            )
        }
    }

    let environment: Environment?
    let libraryItemTypes: [BaseItemKind] = [.episode]
    let parent: TitledLibraryParent
    let parentID: String?
    let seriesID: String?

    init(
        environment: Environment? = nil,
        parent: TitledLibraryParent = .init(displayTitle: L10n.nextUp, id: "next-up"),
        parentID: String? = nil,
        seriesID: String? = nil
    ) {
        self.environment = environment
        self.parent = parent
        self.parentID = parentID
        self.seriesID = seriesID
    }

    func shouldRefreshForUserDataChange(environment: Environment) -> Bool {
        true
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [ItemPatch] {
        var parameters = Paths.GetNextUpParameters()
        parameters.enableRewatching = environment.enableRewatching
        parameters.enableUserData = true
        parameters.fields = PosterSubtitleField.itemFields
        parameters.limit = pageState.pageSize
        parameters.parentID = seriesID == nil ? parentID : nil
        parameters.seriesID = seriesID
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id

        if seriesID == nil, environment.maxNextUp > 0 {
            parameters.nextUpDateCutoff = Date.now.addingTimeInterval(-environment.maxNextUp)
        }

        let request = Paths.getNextUp(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return try pageState.items(from: response)
    }
}
