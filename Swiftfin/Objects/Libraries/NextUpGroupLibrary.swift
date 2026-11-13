//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct NextUpGroupLibrary: BaseItemKindLibrary {

    let enableRewatching: Bool
    let libraryItemTypes: [BaseItemKind] = [.episode]
    let maxDays: Int?
    let parent: TitledLibraryParent
    let parentID: String?
    let seriesID: String?

    init(
        id: String,
        displayTitle: String,
        configuration: NextUpGroupConfiguration
    ) {
        self.enableRewatching = configuration.enableRewatching
        self.maxDays = configuration.maxDays
        self.parent = .init(displayTitle: displayTitle, id: id)
        self.parentID = configuration.library?.id
        self.seriesID = configuration.series?.id
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [ItemPatch] {
        var parameters = Paths.GetNextUpParameters()
        parameters.enableRewatching = enableRewatching
        parameters.enableUserData = true
        parameters.fields = PosterSubtitleField.itemFields
        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id

        parameters.parentID = seriesID == nil ? parentID : nil
        parameters.seriesID = seriesID

        if seriesID == nil, let maxDays {
            parameters.nextUpDateCutoff = Date.now.addingTimeInterval(
                -TimeInterval(maxDays) * 24 * 60 * 60
            )
        }

        let request = Paths.getNextUp(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return try pageState.items(from: response)
    }

    func shouldRefreshForUserDataChange(environment: Empty) -> Bool {
        true
    }
}
