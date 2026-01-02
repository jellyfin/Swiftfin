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

extension ItemSortOrder: Displayable {
    // TODO: Localize
    var displayTitle: String {
        switch self {
        case .ascending:
            return L10n.ascending
        case .descending:
            return L10n.descending
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
