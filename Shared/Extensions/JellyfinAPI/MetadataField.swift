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
            return L10n.people
        case .genres:
            return L10n.genres
        case .productionLocations:
            return L10n.productionLocations
        case .studios:
            return L10n.studios
        case .tags:
            return L10n.tags
        case .name:
            return L10n.name
        case .overview:
            return L10n.overview
        case .runtime:
            return L10n.runtime
        case .officialRating:
            return L10n.officialRating
        }
    }
}
