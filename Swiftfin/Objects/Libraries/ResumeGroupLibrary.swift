//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct ResumeGroupLibrary: BaseItemKindLibrary {

    let itemTypes: [BaseItemKind]
    let parent: TitledLibraryParent
    let parentID: String?
    let searchTerm: String?

    var libraryItemTypes: [BaseItemKind] {
        itemTypes.isEmpty ? [.episode, .movie, .video] : itemTypes
    }

    init(
        id: String,
        displayTitle: String,
        configuration: ResumeGroupConfiguration
    ) {
        self.itemTypes = configuration.itemTypes
        self.parent = .init(displayTitle: displayTitle, id: id)
        self.parentID = configuration.parent?.id
        self.searchTerm = configuration.searchTerm
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [ItemPatch] {
        var parameters = Paths.GetResumeItemsParameters()
        parameters.enableUserData = true
        parameters.fields = PosterSubtitleField.itemFields
        parameters.includeItemTypes = itemTypes.isEmpty ? nil : itemTypes
        parameters.limit = pageState.pageSize
        parameters.parentID = parentID
        parameters.searchTerm = searchTerm
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getResumeItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return try pageState.items(from: response)
    }

    func includes(_ element: ItemEntry, environment: Empty) -> Bool {
        element.item.confirmedUserData?.matches([.isResumable]) != false
    }

    func shouldRefreshForUserDataChange(environment: Empty) -> Bool {
        true
    }
}
