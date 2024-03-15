//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension MediaViewModel {

    enum MediaType: Displayable, Hashable {
        case collectionFolder(BaseItemDto)
        case downloads
        case favorites
        case liveTV(BaseItemDto)

        var displayTitle: String {
            switch self {
            case let .collectionFolder(item):
                return item.displayTitle
            case .downloads:
                return L10n.downloads
            case .favorites:
                return L10n.favorites
            case .liveTV:
                return L10n.liveTV
            }
        }
    }
}
