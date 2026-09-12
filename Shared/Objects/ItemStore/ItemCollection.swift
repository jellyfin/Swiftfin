//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import IdentifiedCollections
import JellyfinAPI

/// Membership is a value; item data is shared. Materialize subsets instead of retaining slices.
typealias ItemCollection = IdentifiedArrayOf<ItemEntry>

extension UserItemDataDto {
    /// Missing fields cannot disqualify a partial response.
    func matches(_ filters: some Sequence<JellyfinAPI.ItemFilter>) -> Bool {
        filters.allSatisfy { filter in
            switch filter {
            case .isFavorite: isFavorite != false
            case .isPlayed: isPlayed != false
            case .isUnplayed: isPlayed != true
            case .isResumable: isPlayed != true && playbackPositionTicks != 0
            case .likes: isLikes != false
            case .dislikes: isLikes != true
            default: true
            }
        }
    }
}

@MainActor
@dynamicMemberLookup
struct ItemEntry: Identifiable, Hashable {

    struct ID: Hashable, Sendable {
        let item: ItemKey
        let occurrence: String?
    }

    nonisolated let id: ID
    let item: ItemRecord
    var presentationType: BaseItemKind?

    init(item: ItemRecord, occurrence: String? = nil, presentationType: BaseItemKind? = nil) {
        self.id = ID(item: item.id, occurrence: occurrence)
        self.item = item
        self.presentationType = presentationType
    }

    var value: BaseItemDto? {
        guard var value = item.value else { return nil }
        value.playlistItemID = id.occurrence
        if let presentationType {
            value.type = presentationType
        }
        return value
    }

    nonisolated var itemID: String {
        id.item.itemID
    }

    // DTO helpers only see a temporary rendering snapshot.
    var snapshot: BaseItemDto {
        value ?? BaseItemDto(id: itemID)
    }

    subscript<Value>(dynamicMember keyPath: KeyPath<BaseItemDto, Value>) -> Value {
        snapshot[keyPath: keyPath]
    }

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
