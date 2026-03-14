//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum ItemViewAttribute: String, CaseIterable, Displayable, Storable {

    case ratingCritics
    case ratingCommunity
    case ratingOfficial
    case videoQuality
    case audioChannels
    case subtitles

    var displayTitle: String {
        switch self {
        case .ratingCritics:
            L10n.criticRating
        case .ratingCommunity:
            L10n.communityRating
        case .ratingOfficial:
            L10n.parentalRating
        case .videoQuality:
            L10n.video
        case .audioChannels:
            L10n.audio
        case .subtitles:
            L10n.subtitles
        }
    }
}
