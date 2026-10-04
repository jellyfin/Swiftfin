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
    case officialRating
    case communityRating
    case criticRating
    case genre
    case quality
    case runtime
    case studio
    case year

    // Fetch these with poster collections so changing labels needs no per-item requests.
    static let itemFields: [ItemFields] = [.mediaStreams, .genres, .studios]

    var displayTitle: String {
        switch self {
        case .none: L10n.none
        case .officialRating: L10n.posterAgeRating
        case .communityRating: L10n.communityRating
        case .criticRating: L10n.criticRating
        case .genre: L10n.genre
        case .quality: L10n.quality
        case .runtime: L10n.runtime
        case .studio: L10n.studio
        case .year: L10n.year
        }
    }
}
