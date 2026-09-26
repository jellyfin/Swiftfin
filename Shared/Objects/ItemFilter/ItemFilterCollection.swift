//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct ItemFilterCollection: Hashable, Storable {

    var audioLanguages: [ItemLanguage] = []
    var categories: [ChannelCategory] = []
    var genres: [ItemGenre] = []
    var itemTypes: [BaseItemKind] = []
    var letter: [ItemLetter] = []
    var officialRatings: [ItemOfficialRating] = []
    var sortBy: [ItemSortBy] = [ItemSortBy.sortName]
    var sortOrder: [ItemSortOrder] = [ItemSortOrder.ascending]
    var subtitleLanguages: [ItemLanguage] = []
    var tags: [ItemTag] = []
    var traits: [ItemTrait] = []
    var years: [ItemYear] = []

    var query: String?

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
        categories: ChannelCategory.allCases,
        letter: ItemLetter.allCases,
        sortBy: ItemSortBy.supportedCases,
        sortOrder: ItemSortOrder.allCases,
        traits: ItemTrait.supportedCases
    )

    var isNotEmpty: Bool {
        self != Self.default
    }

    var hasQueryableFilters: Bool {
        audioLanguages.isNotEmpty ||
            categories.isNotEmpty ||
            genres.isNotEmpty ||
            itemTypes.isNotEmpty ||
            letter.isNotEmpty ||
            officialRatings.isNotEmpty ||
            subtitleLanguages.isNotEmpty ||
            tags.isNotEmpty ||
            traits.isNotEmpty ||
            years.isNotEmpty ||
            !query.isNilOrEmpty
    }

    func containsFilters(ofType type: ItemFilterType) -> Bool {
        type.group.contains { group in
            self[keyPath: group.keyPath] != Self.default[keyPath: group.keyPath]
        }
    }

    /// The union of this collection and another collection, with
    /// precedence given to this collection's values.
    func union(_ other: Self) -> Self {
        var result = other

        func apply(_ keyPath: WritableKeyPath<Self, some Equatable>) {
            if self[keyPath: keyPath] != Self.default[keyPath: keyPath] {
                result[keyPath: keyPath] = self[keyPath: keyPath]
            }
        }

        apply(\.audioLanguages)
        apply(\.categories)
        apply(\.genres)
        apply(\.itemTypes)
        apply(\.letter)
        apply(\.officialRatings)
        apply(\.subtitleLanguages)
        apply(\.tags)
        apply(\.traits)
        apply(\.years)
        apply(\.query)

        if containsFilters(ofType: .sortBy) {
            result.sortBy = sortBy
            result.sortOrder = sortOrder
        }

        return result
    }
}
