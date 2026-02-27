//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum ItemFilterType: String, CaseIterable, Storable, Identifiable {

    case genres
    case letter
    case sortBy
    case sortOrder
    case tags
    case traits
    case years

    var id: String {
        rawValue
    }

    var selectorType: SelectorType {
        switch self {
        case .genres, .tags, .traits, .years:
            .multi
        case .letter, .sortBy, .sortOrder:
            .single
        }
    }

    var collectionAnyKeyPath: KeyPath<ItemFilterCollection, [AnyItemFilter]> {
        switch self {
        case .genres:
            \ItemFilterCollection.genres.asAnyItemFilter
        case .letter:
            \ItemFilterCollection.letter.asAnyItemFilter
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
        case .letter:
            L10n.letter
        case .sortBy:
            L10n.sort
        case .sortOrder:
            L10n.order
        case .tags:
            L10n.tags
        case .traits:
            L10n.filters
        case .years:
            L10n.years
        }
    }
}

extension ItemFilterType: SystemImageable {

    var systemImage: String {
        switch self {
        case .genres:
            "theatermasks"
        case .letter:
            "character.textbox"
        case .sortBy:
            "line.3.horizontal.decrease"
        case .sortOrder:
            "arrow.up.arrow.down"
        case .tags:
            "tag"
        case .traits:
            "heart"
        case .years:
            "calendar"
        }
    }
}
