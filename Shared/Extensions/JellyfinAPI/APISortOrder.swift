//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

typealias APISortOrder = JellyfinAPI.SortOrder

extension APISortOrder: Displayable {
    // TODO: Localize
    var displayTitle: String {
        switch self {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        }
    }
}

extension APISortOrder {

    var filter: ItemFilters.Filter {
        .init(displayTitle: displayTitle, filterName: rawValue)
    }
}
