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

    var categories: [ChannelCategory] = []
    var genres: [ItemGenre] = []
    var itemTypes: [BaseItemKind] = []
    var letter: [ItemLetter] = []
    var sortBy: [ItemSortBy] = [ItemSortBy.sortName]
    var sortOrder: [ItemSortOrder] = [ItemSortOrder.ascending]
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
        categories.isNotEmpty ||
            genres.isNotEmpty ||
            itemTypes.isNotEmpty ||
            letter.isNotEmpty ||
            tags.isNotEmpty ||
            traits.isNotEmpty ||
            years.isNotEmpty ||
            !query.isNilOrEmpty
    }

    /// Applies this collection to the given item request parameters.
    func apply(
        to parameters: Paths.GetItemsParameters,
        isLetterFilterIncluded: Bool = true
    ) -> Paths.GetItemsParameters {
        var parameters = parameters
        parameters.filters = traits
        parameters.genres = genres.map(\.value)
        parameters.sortBy = sortBy
        parameters.sortOrder = sortOrder
        parameters.tags = tags.map(\.value)
        parameters.years = years.compactMap { Int($0.value) }

        parameters.isMovie = categories.contains(.movies) ? true : nil
        parameters.isSeries = categories.contains(.series) ? true : nil
        parameters.isNews = categories.contains(.news) ? true : nil
        parameters.isKids = categories.contains(.kids) ? true : nil
        parameters.isSports = categories.contains(.sports) ? true : nil

        if let query {
            parameters.searchTerm = query
        }

        if itemTypes.isNotEmpty {
            parameters.includeItemTypes = itemTypes
        }

        guard isLetterFilterIncluded else { return parameters }

        if letter.first?.value == "#" {
            parameters.nameLessThan = "A"
        } else {
            parameters.nameStartsWith = letter
                .map(\.value)
                .filter { $0 != "#" }
                .first
        }

        return parameters
    }
}
