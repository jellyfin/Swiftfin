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

    // MARK: - Published Playlist Items

    @Published
    private(set) var playlistItems: [BaseItemDto] = []

    // MARK: - On Refresh

    override func onRefresh() async throws {
        let items = try await self.getPlaylistItems()

        await MainActor.run {
            self.playlistItems = items
        }

        // Try to find first unplayed item
        if let firstUnplayed = items.first(where: { $0.userData?.isPlayed == false }) {
            await MainActor.run {
                self.playButtonItem = firstUnplayed
            }
            return
        }

        // If no unplayed item, use the first item if available
        if let firstItem = items.first {
            await MainActor.run {
                self.playButtonItem = firstItem
            }
        }
    }

    // MARK: - Get Playlist Items

    private func getPlaylistItems() async throws -> [BaseItemDto] {
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = BaseItemKind.supportedCases
            .appending(.episode)
        parameters.parentID = item.id

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
