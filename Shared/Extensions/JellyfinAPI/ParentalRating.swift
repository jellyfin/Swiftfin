//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension ParentalRating: Displayable {

    var displayTitle: String {
        self.name ?? L10n.unknown
    }
}

extension ParentalRating: @retroactive Identifiable {
    public var id: Int {
        hashValue
    }
}

// TODO: I don't think this is a ParentalRating?
extension UnratedItem: Displayable {

    var displayTitle: String {
        switch self {
        case .movie:
            L10n.movies
        case .trailer:
            L10n.trailers
        case .series:
            L10n.tvShows
        case .music:
            L10n.music
        case .book:
            L10n.books
        case .liveTvChannel:
            L10n.liveTVChannels
        case .liveTvProgram:
            L10n.liveTVPrograms
        case .channelContent:
            L10n.channels
        case .other:
            L10n.other
        }
    }
}
