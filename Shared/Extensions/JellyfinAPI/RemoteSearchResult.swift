//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

extension RemoteSearchResult: @retroactive Equatable, @retroactive Identifiable {

    public var id: String {
        UUID().uuidString
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
