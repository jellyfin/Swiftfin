//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct GuideChannelsLibrary: BaseItemKindLibrary {

    let libraryItemTypes: [BaseItemKind] = [.tvChannel]

    let parent: TitledLibraryParent = .init(
        displayTitle: L10n.guide,
        id: "guide-channels"
    )

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetLiveTvChannelsParameters()
        parameters.fields = .MinimumFields
        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getLiveTvChannels(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
