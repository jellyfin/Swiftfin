//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

extension RemoteSearchResult: Displayable {

    var displayTitle: String {
        name ?? L10n.unknown
    }
}

extension RemoteSearchResult: @retroactive Hashable, @retroactive Identifiable {

    public var id: Int {
        hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(albumArtist)
        hasher.combine(artists)
        hasher.combine(imageURL)
        hasher.combine(indexNumber)
        hasher.combine(indexNumberEnd)
        hasher.combine(name)
        hasher.combine(overview)
        hasher.combine(parentIndexNumber)
        hasher.combine(premiereDate)
        hasher.combine(productionYear)
        hasher.combine(providerIDs)
        hasher.combine(searchProviderName)
    }

    public static func == (lhs: RemoteSearchResult, rhs: RemoteSearchResult) -> Bool {
        lhs.albumArtist == rhs.albumArtist &&
            lhs.artists == rhs.artists &&
            lhs.imageURL == rhs.imageURL &&
            lhs.indexNumber == rhs.indexNumber &&
            lhs.indexNumberEnd == rhs.indexNumberEnd &&
            lhs.name == rhs.name &&
            lhs.overview == rhs.overview &&
            lhs.parentIndexNumber == rhs.parentIndexNumber &&
            lhs.premiereDate == rhs.premiereDate &&
            lhs.productionYear == rhs.productionYear &&
            lhs.providerIDs == rhs.providerIDs &&
            lhs.searchProviderName == rhs.searchProviderName
    }
}
