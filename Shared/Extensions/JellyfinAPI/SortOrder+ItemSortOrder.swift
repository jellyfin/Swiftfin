//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// Necessary to handle conflict with Foundation.SortOrder
typealias ItemSortOrder = JellyfinAPI.SortOrder

extension ItemSortOrder: Displayable, SystemImageable {

    var displayTitle: String {
        switch self {
        case .descending:
            L10n.descending
        case .ascending:
            L10n.ascending
        }
    }

    var systemImage: String {
        switch self {
        case .descending:
            "arrowtriangle.down"
        case .ascending:
            "arrowtriangle.up"
        }
    }
}

extension ItemSortOrder: ItemFilter {

    var value: String {
        rawValue
    }

    init(from anyFilter: AnyItemFilter) {
        self.init(rawValue: anyFilter.value)!
    }
}
