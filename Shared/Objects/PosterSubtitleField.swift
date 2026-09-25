//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

enum PosterSubtitleField: String, CaseIterable, Displayable, Storable {
    case none
    case year
    case runtime
    case officialRating
    case communityRating
    case criticRating
    case quality
    case genre
    case studio
    case episodeNumber
    case title
    case extraType

    // Fetch these with poster collections so changing labels needs no per-item requests.
    static let itemFields: [ItemFields] = [.mediaStreams, .genres, .studios]

    var displayTitle: String {
        switch self {
        case .none: L10n.none
        case .year: L10n.year
        case .runtime: L10n.runtime
        case .officialRating: L10n.posterAgeRating
        case .communityRating: L10n.communityRating
        case .criticRating: L10n.criticRating
        case .quality: L10n.quality
        case .genre: L10n.genre
        case .studio: L10n.studio
        case .episodeNumber: L10n.posterEpisodeNumber
        case .title: L10n.title
        case .extraType: L10n.posterExtraType
        }
    }
}
