//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

extension ItemFilter: Displayable {
    var displayName: String {
        localized
    }
}

extension String: Displayable {
    var displayName: String {
        self
    }
}

// TODO: Look at refactoring everything in this file, probably move to JellyfinAPI
struct ItemFilters: Hashable {

    var genres: [Filter] = []
    var tags: [Filter] = []
    var filters: [Filter] = []
    var sortOrder: [Filter] = [APISortOrder.ascending.filter]
    var sortBy: [Filter] = [SortBy.name.filter]

    static let all: ItemFilters = .init(
        filters: ItemFilter.supportedCases.map(\.filter),
        sortOrder: APISortOrder.allCases.map(\.filter),
        sortBy: SortBy.allCases.map(\.filter)
    )
    static let favorites: ItemFilters = .init(filters: [ItemFilter.isFavorite.filter])
    static let recent: ItemFilters = .init(sortOrder: [APISortOrder.descending.filter], sortBy: [SortBy.dateAdded.filter])

    var hasFilters: Bool {
        self != .init()
    }

    // Type-erased object for use with FilterView and WritableKeyPath
    struct Filter: Displayable, Hashable, Identifiable {
        var displayName: String
        var id: String?
        var filterName: String
    }
}

public enum SortBy: String, Codable, CaseIterable {
    case premiereDate = "PremiereDate"
    case name = "SortName"
    case dateAdded = "DateCreated"
    case random = "Random"

    // TODO: Localize
    var localized: String {
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
        .init(displayName: localized, filterName: rawValue)
    }
}

extension ItemFilter {
    static var supportedCases: [ItemFilter] {
        [.isUnplayed, .isPlayed, .isFavorite, .likes]
    }

    // TODO: Localize
    var localized: String {
        switch self {
        case .isUnplayed:
            return "Unplayed"
        case .isPlayed:
            return "Played"
        case .isFavorite:
            return "Favorites"
        case .likes:
            return "Liked Items"
        default:
            return ""
        }
    }

    var filter: ItemFilters.Filter {
        .init(displayName: localized, filterName: rawValue)
    }
}

extension APISortOrder {
    // TODO: Localize
    var localized: String {
        switch self {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        }
    }

    var filter: ItemFilters.Filter {
        .init(displayName: localized, filterName: rawValue)
    }
}

// TODO: Remove
enum ItemType: String {
    case episode = "Episode"
    case movie = "Movie"
    case series = "Series"
    case season = "Season"

    var localized: String {
        switch self {
        case .episode:
            return L10n.episodes
        case .movie:
            return "Movies"
        case .series:
            return "Shows"
        default:
            return ""
        }
    }
}
