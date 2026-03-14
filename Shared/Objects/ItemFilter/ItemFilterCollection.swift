//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

/// A structure representing a collection of item filters
struct ItemFilterCollection: Hashable, Storable {

    var genres: [ItemGenre] = []
    var itemTypes: [BaseItemKind] = []
    var letter: [ItemLetter] = []
    var sortBy: [ItemSortBy] = [ItemSortBy.sortName]
    var sortOrder: [ItemSortOrder] = [ItemSortOrder.ascending]
    var tags: [ItemTag] = []
    var traits: [ItemTrait] = []
    var years: [ItemYear] = []

    /// The default collection of filters
    static let `default`: ItemFilterCollection = .init()

    static let favorites: ItemFilterCollection = .init(
        traits: [ItemTrait.isFavorite]
    )
    static let recent: ItemFilterCollection = .init(
        sortBy: [ItemSortBy.dateCreated],
        sortOrder: [ItemSortOrder.descending]
    )

    /// A collection that has all statically available values.
    ///
    /// These may be altered when used to better represent all
    /// available values within the current context.
    static let all: ItemFilterCollection = .init(
        letter: ItemLetter.allCases,
        sortBy: ItemSortBy.supportedCases,
        sortOrder: ItemSortOrder.allCases,
        traits: ItemTrait.supportedCases
    )

    var hasFilters: Bool {
        self != Self.default
    }

    var hasQueryableFilters: Bool {
        genres.isNotEmpty || itemTypes.isNotEmpty || letter.isNotEmpty || tags.isNotEmpty || traits.isNotEmpty || years.isNotEmpty
    }

    var activeFilterCount: Int {
        var count = 0

        for filter in ItemFilterType.allCases {
            if self[keyPath: filter.collectionAnyKeyPath] != Self.default[keyPath: filter.collectionAnyKeyPath] {
                count += 1
            }
        }

        return count
    }
}
