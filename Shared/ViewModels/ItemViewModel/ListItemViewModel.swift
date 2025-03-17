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

final class ListItemViewModel: ItemViewModel {

    @Published
    private(set) var listItems: [BaseItemDto] = []

    override func onRefresh() async throws {
        let listItems = try await self.getListItems()

        await MainActor.run {
            self.listItems = listItems
        }

        let firstUnplayed = listItems.first { $0.userData?.isPlayed == false }

        if firstUnplayed != nil {
            await MainActor.run {
                self.playButtonItem = firstUnplayed
            }
        } else if let first = listItems.first {
            await MainActor.run {
                self.playButtonItem = first
            }
        }
    }

    private func getListItems() async throws -> [BaseItemDto] {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.parentID = item.id

        // Hide unsupported item types
        parameters.includeItemTypes = [.movie, .episode, .series, .boxSet]

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
