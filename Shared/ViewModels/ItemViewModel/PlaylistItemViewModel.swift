//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class PlaylistItemViewModel: ItemViewModel {

    @Published
    private(set) var playlistItems: [BaseItemDto] = []

    override func onRefresh() async throws {
        let playlistItems = try await self.getPlaylistItems()

        await MainActor.run {
            self.playlistItems = playlistItems
        }
    }

    private func getPlaylistItems() async throws -> [BaseItemDto] {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.parentID = item.id

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
