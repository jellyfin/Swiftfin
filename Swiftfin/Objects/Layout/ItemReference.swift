//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct ItemReference: Codable, Hashable, Identifiable, Displayable, SystemImageable {

    let id: String
    var name: String
    var itemType: BaseItemKind?

    init(
        id: String,
        name: String,
        itemType: BaseItemKind? = nil
    ) {
        self.id = id
        self.name = name
        self.itemType = itemType
    }

    init(item: BaseItemDto) {
        self.init(
            id: item.id ?? "",
            name: item.displayTitle,
            itemType: item.type
        )
    }

    var displayTitle: String {
        name.nilIfEmpty ?? L10n.unknown
    }

    var systemImage: String {
        baseItem.systemImage
    }

    var baseItem: BaseItemDto {
        BaseItemDto(
            id: id,
            name: displayTitle,
            type: itemType
        )
    }
}
