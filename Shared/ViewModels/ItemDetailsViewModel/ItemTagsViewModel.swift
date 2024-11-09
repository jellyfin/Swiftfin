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

class ItemTagsViewModel: ItemDetailsViewModel<String> {

    // MARK: - Add Details

    override func addItems(_ tags: [String]) async throws {
        var updatedItem = item
        if updatedItem.tags == nil {
            updatedItem.tags = []
        }
        updatedItem.tags?.append(contentsOf: tags)
        _ = updateItem(updatedItem)
    }

    // MARK: - Remove Details

    override func removeItems(_ tags: [String]) async throws {
        var updatedItem = item
        updatedItem.tags?.removeAll { tags.contains($0) }
        _ = updateItem(updatedItem)
    }
}
