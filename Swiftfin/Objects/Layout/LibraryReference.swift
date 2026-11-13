//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct LibraryReference: Codable, Hashable, Identifiable, Displayable, SystemImageable {

    let id: String
    var name: String
    var itemType: BaseItemKind?
    var collectionType: CollectionType?

    init(
        id: String,
        name: String,
        itemType: BaseItemKind? = nil,
        collectionType: CollectionType? = nil
    ) {
        self.id = id
        self.name = name
        self.itemType = itemType
        self.collectionType = collectionType
    }

    init(library: BaseItemDto) {
        self.init(
            id: library.id ?? "",
            name: library.displayTitle,
            itemType: library.type,
            collectionType: library.collectionType
        )
    }

    var displayTitle: String {
        name.nilIfEmpty ?? L10n.libraries
    }

    var systemImage: String {
        baseItem.systemImage
    }

    var baseItem: BaseItemDto {
        var item = BaseItemDto(
            id: id,
            name: displayTitle,
            type: itemType
        )
        item.collectionType = collectionType
        return item
    }
}
