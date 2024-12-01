//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

class TagEditorViewModel: ItemEditorViewModel<String> {

    // MARK: - Add Details

    override func addComponents(_ tags: [String]) async throws {
        var updatedItem = item
        if updatedItem.tags == nil {
            updatedItem.tags = []
        }
        updatedItem.tags?.append(contentsOf: tags)
        try await updateItem(updatedItem)
    }

    // MARK: - Remove Details

    override func removeComponents(_ tags: [String]) async throws {
        var updatedItem = item
        updatedItem.tags?.removeAll { tags.contains($0) }
        try await updateItem(updatedItem)
    }

    // MARK: - Validate Details

    override func searchComponent(_ tag: String) async throws -> [String] {
        let parameters = Paths.GetItemsParameters(
            userID: userSession.user.id,
            limit: 1,
            isRecursive: true,
            tags: [tag]
        )
        let request = Paths.getItems(parameters: parameters)
        let response = try await userSession.client.send(request)

        // TODO: Replace with a getTags search (If it exists)
        // See if there are any items with this Tag
        if response.value.items?.isEmpty ?? false {
            return []
        } else {
            return [tag]
        }
    }
}
