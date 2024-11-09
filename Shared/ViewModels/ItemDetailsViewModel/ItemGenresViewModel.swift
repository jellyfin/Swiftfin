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

class ItemGenreViewModel: ItemDetailsViewModel<String> {

    // MARK: - Add Details

    override func addItems(_ genres: [String]) async throws {
        var updatedItem = item
        if updatedItem.genres == nil {
            updatedItem.genres = []
        }
        updatedItem.genres?.append(contentsOf: genres)
        _ = updateItem(updatedItem)
    }

    // MARK: - Remove Details

    override func removeItems(_ genres: [String]) async throws {
        var updatedItem = item
        updatedItem.genres?.removeAll { genres.contains($0) }
        _ = updateItem(updatedItem)
    }
}
