//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct RecordingsLibrary: BaseItemKindLibrary {

    let libraryItemTypes: [BaseItemKind] = [.movie, .episode, .video]
    let parent: TitledLibraryParent = .init(
        displayTitle: L10n.recordings,
        id: "recordings"
    )

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetRecordingsParameters()
        parameters.userID = pageState.userSession.user.id
        parameters.startIndex = pageState.pageOffset
        parameters.limit = pageState.pageSize
        parameters.fields = .MinimumFields.appending(.channelInfo)
        parameters.enableUserData = true
        parameters.isInProgress = false

        let request = Paths.getRecordings(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
