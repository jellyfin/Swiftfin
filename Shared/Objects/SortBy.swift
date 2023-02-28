//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// TODO: Move to jellyfin-api-swift

enum SortBy: String, CaseIterable, Displayable {

    case premiereDate = "PremiereDate"
    case name = "SortName"
    case dateAdded = "DateCreated"
    case random = "Random"

    // TODO: Localize
    var displayTitle: String {
        switch self {
        case .premiereDate:
            return "Premiere date"
        case .name:
            return "Name"
        case .dateAdded:
            return "Date added"
        case .random:
            return "Random"
        }
    }

    var filter: ItemFilters.Filter {
        .init(displayTitle: displayTitle, filterName: rawValue)
    }
}
