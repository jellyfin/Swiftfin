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
    case productionYear = "ProductionYear"
    case premiereDate = "PremiereDate"
    case name = "SortName"
    case dateAdded = "DateCreated"
}

extension SortBy {
    var localized: String {
        switch self {
        case .productionYear:
            return "Release Year"
        case .premiereDate:
            return "Premiere date"
        case .name:
            return "Title"
        case .dateAdded:
            return "Date added"
        }
    }
}

extension ItemFilter {
    static var supportedTypes: [ItemFilter] {
        [.isUnplayed, isPlayed, .isFavorite, .likes, .isFavoriteOrLikes]
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
            return "Liked"
        case .isFavoriteOrLikes:
            return "Favorites or Liked"
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
