//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension MetadataField: Displayable {
    var displayTitle: String {
        switch self {
        case .cast:
            L10n.people
        case .genres:
            L10n.genres
        case .productionLocations:
            L10n.productionLocations
        case .studios:
            L10n.studios
        case .tags:
            L10n.tags
        case .name:
            L10n.name
        case .overview:
            L10n.overview
        case .runtime:
            L10n.runtime
        case .officialRating:
            L10n.officialRating
        }
    }
}
