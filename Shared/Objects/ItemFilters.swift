//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI

struct ItemFilters: Codable, Defaults.Serializable, Hashable {

    var genres: [Filter] = []
    var filters: [Filter] = []
    var sortOrder: [Filter] = [APISortOrder.ascending.filter]
    var sortBy: [Filter] = [SortBy.name.filter]

    static let favorites: ItemFilters = .init(filters: [ItemFilter.isFavorite.filter])
    static let recent: ItemFilters = .init(sortOrder: [APISortOrder.descending.filter], sortBy: [SortBy.dateAdded.filter])
    static let all: ItemFilters = .init(
        filters: ItemFilter.supportedCases.map(\.filter),
        sortOrder: APISortOrder.allCases.map(\.filter),
        sortBy: SortBy.allCases.map(\.filter)
    )

    var hasFilters: Bool {
        self != .init()
    }

    // Type-erased object for use with WritableKeyPath
    struct Filter: Codable, Defaults.Serializable, Displayable, Hashable, Identifiable {
        var displayTitle: String
        var id: String?
        var filterName: String
    }
}
