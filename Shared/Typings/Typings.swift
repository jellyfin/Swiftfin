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
    var sortOrder: [SortOrder] = [.descending]
    var withGenres: [NameGuidPair] = []
    var sortBy: [String] = ["SortName"]
}

public enum SortBy: String, Codable, CaseIterable {
    case productionYear = "ProductionYear"
    case premiereDate = "PremiereDate"
    case name = "SortName"
    case dateAdded = "DateCreated"
}

class justSignedIn: ObservableObject {
    @Published var did: Bool = false
}

class GlobalData: ObservableObject {
    @Published var user: SignedInUser!
    @Published var authToken: String = ""
    @Published var server: Server!
    @Published var authHeader: String = ""
    @Published var isInNetwork: Bool = true
    @Published var networkError: Bool = false
    @Published var expiredCredentials: Bool = false
    var pendingAPIRequests = Set<AnyCancellable>()
}

extension GlobalData: Equatable {

    static func == (lhs: GlobalData, rhs: GlobalData) -> Bool {
        lhs.user == rhs.user
            && lhs.authToken == rhs.authToken
            && lhs.server == rhs.server
            && lhs.authHeader == rhs.authHeader
    }
}
