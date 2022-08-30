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

// TODO: Look at refactoring everything in this file, probably move to JellyfinAPI
struct LibraryFilters: Codable, Hashable {
    var filters: [ItemFilter] = []
    var sortOrder: [APISortOrder] = [.ascending]
    var withGenres: [NameGuidPair] = []
    var tags: [String] = []
    var sortBy: [SortBy] = [.name]

    static let `default` = LibraryFilters()
    static let favorites: LibraryFilters = .init(filters: [.isFavorite], sortOrder: [.ascending], sortBy: [.name])
}

public enum SortBy: String, Codable, CaseIterable {
    case premiereDate = "PremiereDate"
    case name = "SortName"
    case dateAdded = "DateCreated"
    case random = "Random"
}

extension SortBy {
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
}

extension ItemFilter {
    static var supportedTypes: [ItemFilter] {
        [.isUnplayed, isPlayed, .isFavorite, .likes]
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
