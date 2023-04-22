//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension ItemFilter: Displayable {
    // TODO: Localize
    var displayTitle: String {
        switch self {
        case .isUnplayed:
            return "Unplayed"
        case .isPlayed:
            return "Played"
        case .isFavorite:
            return "Favorites"
        case .likes:
            return "Liked Items"
        default:
            return ""
        }
    }
}

extension ItemFilter {

    static var supportedCases: [ItemFilter] {
        [.isUnplayed, .isPlayed, .isFavorite, .likes]
    }

    var filter: ItemFilters.Filter {
        .init(displayTitle: displayTitle, filterName: rawValue)
    }
}
