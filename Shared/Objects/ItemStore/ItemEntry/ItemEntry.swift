//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// Represents one occurrence of an item backed by a shared record
@MainActor
struct ItemEntry: Identifiable, Hashable {

    /// Distinguishes repeated appearances of the same item in a collection
    struct ID: Hashable, Sendable {

        let itemID: String
        let occurrence: String?
    }

    nonisolated let id: ID
    let item: ItemRecord

    init(item: ItemRecord, occurrence: String? = nil) {
        self.id = ID(itemID: item.id, occurrence: occurrence)
        self.item = item
    }

    var value: BaseItemDto? {
        guard var value = item.value else { return nil }

        // Apply playlist identity to this occurrence without changing the shared record
        value.playlistItemID = id.occurrence
        return value
    }

    nonisolated var itemID: String {
        id.itemID
    }

    /// Keeps the item ID available after its record is invalidated
    var snapshot: BaseItemDto {
        value ?? BaseItemDto(id: itemID)
    }

    // Metadata changes do not change the identity of an entry
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
