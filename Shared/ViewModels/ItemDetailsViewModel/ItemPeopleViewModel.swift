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

class ItemPeopleViewModel: ItemDetailsViewModel<BaseItemPerson> {

    // MARK: - Add Details

    override func addItems(_ people: [BaseItemPerson]) async throws {
        var updatedItem = item
        if updatedItem.people == nil {
            updatedItem.people = []
        }
        updatedItem.people?.append(contentsOf: people)
        _ = updateItem(updatedItem, refresh: true)
    }

    // MARK: - Remove Details

    override func removeItems(_ people: [BaseItemPerson]) async throws {
        var updatedItem = item
        updatedItem.people?.removeAll { people.contains($0) }
        _ = updateItem(updatedItem, refresh: true)
    }
}
