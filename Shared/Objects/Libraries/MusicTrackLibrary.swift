//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct MusicTrackLibrary: BaseItemKindLibrary {

    let hasNextPage = false
    let libraryItemTypes: [BaseItemKind] = [.audio]
    let parent: BaseItemDto

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        guard let parentID = parent.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        var parameters = Paths.GetItemsParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
//        parameters.isRecursive = true
        parameters.parentID = parentID
        parameters.sortBy = [.album, .parentIndexNumber, .indexNumber, .sortName]
        parameters.sortOrder = [.ascending]
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
