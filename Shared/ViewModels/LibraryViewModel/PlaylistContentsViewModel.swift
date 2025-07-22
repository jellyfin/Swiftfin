//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

final class PlaylistContentsViewModel: PagingLibraryViewModel<BaseItemDto> {

    override func get(page: Int) async throws -> [BaseItemDto] {
        guard let parentID = parent?.id else { return [] }

        var parameters = Paths.GetPlaylistItemsParameters()
        parameters.userID = userSession.user.id
        parameters.startIndex = page * pageSize
        parameters.limit = pageSize
        parameters.fields = ItemFields.MinimumFields
        parameters.enableUserData = true
        parameters.enableImages = true

        let request = Paths.getPlaylistItems(
            playlistID: parentID,
            parameters: parameters
        )

        let response = try await userSession.client.send(request)
        return response.value.items ?? []
    }
}
