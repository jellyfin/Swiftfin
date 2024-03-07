//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum ItemFilterType: String, CaseIterable, Defaults.Serializable {

    case genres
    case sortBy
    case sortOrder
    case tags
    case traits
    case years

    // TODO: rename to something indicating plurality instead of concrete type?
    var selectorType: SelectorType {
        switch self {
        case .genres, .tags, .traits, .years:
            return .multi
        case .sortBy, .sortOrder:
            return .single
        }
    }

    var collectionAnyKeyPath: KeyPath<ItemFilterCollection, [AnyItemFilter]> {
        switch self {
        case .genres:
            \ItemFilterCollection.genres.asAnyItemFilter
        case .sortBy:
            \ItemFilterCollection.sortBy.asAnyItemFilter
        case .sortOrder:
            \ItemFilterCollection.sortOrder.asAnyItemFilter
        case .tags:
            \ItemFilterCollection.tags.asAnyItemFilter
        case .traits:
            \ItemFilterCollection.traits.asAnyItemFilter
        case .years:
            \ItemFilterCollection.years.asAnyItemFilter
        }
    }
}

extension ItemFilterType: Displayable {

    var displayTitle: String {
        switch self {
        case .genres:
            L10n.genres
        case .sortBy:
            L10n.sort
        case .sortOrder:
            L10n.order
        case .tags:
            L10n.tags
        case .traits:
            L10n.filters
        case .years:
            "Years"
        }
    }
}
