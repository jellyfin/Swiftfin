//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI

struct LatestInLibrary: BaseItemKindLibrary {

    struct Environment: WithDefaultValue {

        var enableRewatching: Bool

        static let `default`: Self = .init(
            enableRewatching: Defaults[.Customization.Home.Rewatching.configuration].latest
        )
    }

    let hasNextPage = false

    let libraryItemTypes: [BaseItemKind]
    let parent: TitledLibraryParent

    init(library: BaseItemDto) {
        self.parent = .init(
            displayTitle: L10n.latestWithString(library.displayTitle),
            id: library.id
        )
        self.libraryItemTypes = library.supportedItemTypes
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [ItemPatch] {
        var parameters = Paths.GetLatestMediaParameters()
        parameters.enableUserData = true
        parameters.fields = PosterSubtitleField.itemFields
        parameters.isPlayed = environment.enableRewatching ? nil : false
        parameters.limit = pageState.pageSize
        parameters.parentID = parent.id
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getLatestMedia(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return try pageState.items(from: response)
    }

    func includes(_ element: ItemEntry, environment: Environment) -> Bool {
        environment.enableRewatching || element.item.confirmedUserData?.matches([.isUnplayed]) != false
    }
}
