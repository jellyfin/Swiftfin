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
            return "Production year"
        case .premiereDate:
            return "Premiere date"
        case .name:
            return "Name"
        case .dateAdded:
            return "Date created"
        }
    }
}

extension ItemFilter {
    var localized: String {
        switch self {
        case .isFolder:
            return "Is folder"
        case .isNotFolder:
            return "Is not folder"
        case .isUnplayed:
            return "Is unplayed"
        case .isPlayed:
            return "Is played"
        case .isFavorite:
            return "Is favorite"
        case .isResumable:
            return "Is resumable"
        case .likes:
            return "Likes"
        case .dislikes:
            return "Dislikes"
        case .isFavoriteOrLikes:
            return "Is favorite or likes"
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
