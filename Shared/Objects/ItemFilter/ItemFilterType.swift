//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

enum ItemFilterType: String, CaseIterable, Displayable, Identifiable, Storable, SystemImageable {

    typealias Group = (
        displayTitle: String,
        keyPath: KeyPath<ItemFilterCollection, [AnyItemFilter]>,
        setter: @MainActor ([AnyItemFilter], FilterViewModel) -> Void,
        selectorType: SelectorType
    )

    case genres
    case letter
    case sortBy
    case tags
    case traits
    case years

    var displayTitle: String {
        switch self {
        case .genres:
            L10n.genres
        case .letter:
            L10n.letter
        case .sortBy:
            L10n.sort
        case .tags:
            L10n.tags
        case .traits:
            L10n.filters
        case .years:
            L10n.years
        }
    }

    @ArrayBuilder<Group>
    var group: [Group] {
        switch self {
        case .genres:
            (
                displayTitle: displayTitle,
                keyPath: \ItemFilterCollection.genres.asAnyItemFilter,
                setter: { $1.currentFilters.genres = $0.map(ItemGenre.init) },
                selectorType: .multi
            )
        case .letter:
            (
                displayTitle: displayTitle,
                keyPath: \ItemFilterCollection.letter.asAnyItemFilter,
                setter: { $1.currentFilters.letter = $0.map(ItemLetter.init) },
                selectorType: .single
            )
        case .sortBy:
            (
                displayTitle: L10n.order,
                keyPath: \ItemFilterCollection.sortOrder.asAnyItemFilter,
                setter: { $1.currentFilters.sortOrder = $0.map(ItemSortOrder.init) },
                selectorType: .single
            )
            (
                displayTitle: displayTitle,
                keyPath: \ItemFilterCollection.sortBy.asAnyItemFilter,
                setter: { $1.currentFilters.sortBy = $0.map(ItemSortBy.init) },
                selectorType: .single
            )
        case .tags:
            (
                displayTitle: displayTitle,
                keyPath: \ItemFilterCollection.tags.asAnyItemFilter,
                setter: { $1.currentFilters.tags = $0.map(ItemTag.init) },
                selectorType: .multi
            )
        case .traits:
            (
                displayTitle: displayTitle,
                keyPath: \ItemFilterCollection.traits.asAnyItemFilter,
                setter: { $1.currentFilters.traits = $0.map(ItemTrait.init) },
                selectorType: .multi
            )
        case .years:
            (
                displayTitle: displayTitle,
                keyPath: \ItemFilterCollection.years.asAnyItemFilter,
                setter: { $1.currentFilters.years = $0.map(ItemYear.init) },
                selectorType: .multi
            )
        }
    }

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .genres:
            "theatermasks"
        case .letter:
            "character.textbox"
        case .sortBy:
            "line.3.horizontal.decrease"
        case .tags:
            "tag"
        case .traits:
            "heart"
        case .years:
            "calendar"
        }
    }
}
