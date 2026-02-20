//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension ItemSortBy: Displayable, SupportedCaseIterable {
    var displayTitle: String {
        switch self {
        case .default:
            L10n.default
        case .airedEpisodeOrder:
            L10n.airedEpisodeOrder
        case .album:
            L10n.album
        case .albumArtist:
            L10n.albumArtist
        case .artist:
            L10n.artist
        case .dateCreated:
            L10n.dateCreated
        case .officialRating:
            L10n.officialRating
        case .datePlayed:
            L10n.datePlayed
        case .premiereDate:
            L10n.premiereDate
        case .startDate:
            L10n.startDate
        case .sortName:
            L10n.sortName
        case .name:
            L10n.name
        case .random:
            L10n.random
        case .runtime:
            L10n.runtime
        case .communityRating:
            L10n.communityRating
        case .productionYear:
            L10n.year
        case .playCount:
            L10n.playCount
        case .criticRating:
            L10n.criticRating
        case .isFolder:
            L10n.folder
        case .isUnplayed:
            L10n.unplayed
        case .isPlayed:
            L10n.played
        case .seriesSortName:
            L10n.seriesName
        case .videoBitRate:
            L10n.videoBitRate
        case .airTime:
            L10n.airTime
        case .studio:
            L10n.studio
        case .isFavoriteOrLiked:
            L10n.favorite
        case .dateLastContentAdded:
            L10n.dateAdded
        case .seriesDatePlayed:
            L10n.seriesDatePlayed
        case .parentIndexNumber:
            L10n.parentIndexNumber
        case .indexNumber:
            L10n.indexNumber
        }
    }

    static var supportedCases: [ItemSortBy] {
        [
            .premiereDate,
            .name,
            .sortName,
            .dateLastContentAdded,
            .random,
        ]
    }
}

extension ItemSortBy: ItemFilter {

    var value: String {
        rawValue
    }

    init(from anyFilter: AnyItemFilter) {
        self.init(rawValue: anyFilter.value)!
    }
}
