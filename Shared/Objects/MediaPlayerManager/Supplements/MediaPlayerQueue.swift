//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import IdentifiedCollections
import JellyfinAPI

protocol MediaPlayerQueue: MediaPlayerListener, MediaPlayerSupplement {

    var hasNextItem: Bool { get }
    var hasPreviousItem: Bool { get }

    var items: IdentifiedArrayOf<BaseItemDto> { get set }

    var nextItem: BaseItemDto? { get }
    var previousItem: BaseItemDto? { get }
}

extension MediaPlayerQueue {

    var hasNextItem: Bool {
        nextItem != nil
    }

    var hasPreviousItem: Bool {
        previousItem != nil
    }

    var nextItem: BaseItemDto? {
        guard let currentItem = manager?.item,
              let i = items.index(id: currentItem.id),
              i != items.endIndex else { return nil }

        return items[items.index(after: i)]
    }

    var previousItem: BaseItemDto? {
        guard let currentItem = manager?.item,
              let i = items.index(id: currentItem.id),
              i != items.startIndex else { return nil }

        return items[items.index(before: i)]
    }
}
