//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension MediaViewModel {

    enum MediaType: Displayable, Hashable, Identifiable {

        case collectionFolder(BaseItemDto)
        case downloads
        case favorites
        case liveTV(BaseItemDto)

        var displayTitle: String {
            switch self {
            case let .collectionFolder(item):
                item.displayTitle
            case .downloads:
                L10n.downloads
            case .favorites:
                L10n.favorites
            case .liveTV:
                L10n.liveTV
            }
        }

        var id: String? {
            switch self {
            case let .collectionFolder(item):
                item.id
            case .downloads:
                "downloads"
            case .favorites:
                "favorites"
            case let .liveTV(item):
                item.id
            }
        }
    }
}
