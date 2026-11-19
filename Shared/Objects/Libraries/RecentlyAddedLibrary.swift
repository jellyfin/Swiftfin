//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI

struct RecentlyAddedLibrary: BaseItemKindLibrary {

    struct Environment: WithDefaultValue {

        var enableRewatching: Bool

        static let `default`: Self = .init(
            enableRewatching: Defaults[.Customization.Home.Rewatching.configuration].recentlyAdded
        )
    }

    let libraryItemTypes: [BaseItemKind] = [.movie, .series]
    let parent: TitledLibraryParent = .init(displayTitle: L10n.recentlyAdded.localizedCapitalized, id: "recently-added")

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [ItemPatch] {
        var parameters = Paths.GetItemsParameters()
        parameters.enableUserData = true
        parameters.fields = PosterSubtitleField.itemFields
        parameters.includeItemTypes = [.movie, .series]
        parameters.isPlayed = environment.enableRewatching ? nil : false
        parameters.isRecursive = true
        parameters.limit = pageState.pageSize
        parameters.sortBy = [.dateCreated]
        parameters.sortOrder = [.descending]
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return try pageState.items(from: response)
    }

    func includes(_ element: ItemEntry, environment: Environment) -> Bool {
        environment.enableRewatching || element.item.confirmedUserData?.matches([.isUnplayed]) != false
    }
}
