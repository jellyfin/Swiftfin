/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import Combine
import JellyfinAPI

struct LibraryFilters: Codable, Hashable {
    var filters: [ItemFilter] = []
    var sortOrder: [APISortOrder] = [.descending]
    var withGenres: [NameGuidPair] = []
    var sortBy: [String] = ["SortName"]
}

public enum SortBy: String, Codable, CaseIterable {
    case productionYear = "ProductionYear"
    case premiereDate = "PremiereDate"
    case name = "SortName"
    case dateAdded = "DateCreated"
}
