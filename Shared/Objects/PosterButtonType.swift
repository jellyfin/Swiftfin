//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation

// TODO: Replace with better mechanism

enum PosterButtonType<Item: Poster>: Hashable, Identifiable {

    case loading
    case noResult
    case item(Item)

    var id: Int {
        switch self {
        case .loading, .noResult:
            return UUID().hashValue
        case let .item(item):
            return item.hashValue
        }
    }

    var _item: Item? {
        switch self {
        case let .item(item):
            return item
        default:
            return nil
        }
    }
}
