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
        // The KefinTweaks "Watchlist" — items the user marked via the Jellyfin `Likes` flag.
        // Only surfaced on tvOS (see `MediaViewModel`), so iOS is unaffected.
        case watchlist

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
            case .watchlist:
                // Matches the on-item "Watchlist" action button label.
                "Watchlist"
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
            case .watchlist:
                "watchlist"
            }
        }

        /// Fallback icon (tvOS) for tiles whose backdrop artwork is missing/empty.
        var systemImage: String {
            switch self {
            case .collectionFolder:
                "rectangle.stack.fill"
            case .downloads:
                "arrow.down.circle.fill"
            case .favorites:
                "heart.fill"
            case .liveTV:
                "tv.fill"
            case .watchlist:
                "bookmark.fill"
            }
        }
    }
}
