/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import Foundation
import JellyfinAPI

struct LibraryFilters: Codable, Hashable {
    var filters: [ItemFilter] = []
    var sortOrder: [APISortOrder] = [.descending]
    var withGenres: [NameGuidPair] = []
    var tags: [String] = []
    var sortBy: [SortBy] = [.name]
}

public enum SortBy: String, Codable, CaseIterable {
    case premiereDate = "PremiereDate"
    case name = "SortName"
    case dateAdded = "DateCreated"
}

extension SortBy {
    var localized: String {
        switch self {
        case .premiereDate:
            return "Premiere date"
        case .name:
            return "Name"
        case .dateAdded:
            return "Date added"
        }
    }
}

extension ItemFilter {
    static var supportedTypes: [ItemFilter] {
        [.isUnplayed, isPlayed, .isFavorite, .likes]
    }

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
    var localized: String {
        switch self {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        }
    }
}

enum ItemType: String {
    case episode = "Episode"
    case movie = "Movie"
    case series = "Series"
    case season = "Season"

    var localized: String {
        switch self {
        case .episode:
            return "Episodes"
        case .movie:
            return "Movies"
        case .series:
            return "Shows"
        default:
            return ""
        }
    }
}
