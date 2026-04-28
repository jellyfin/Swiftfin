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
        case .airedEpisodeOrder:
            L10n.airedEpisodeOrder
        case .airTime:
            L10n.airTime
        case .album:
            L10n.album
        case .albumArtist:
            L10n.albumArtist
        case .artist:
            L10n.artist
        case .communityRating:
            L10n.communityRating
        case .criticRating:
            L10n.criticRating
        case .dateCreated:
            L10n.dateCreated
        case .dateLastContentAdded:
            L10n.dateLastContentAdded
        case .datePlayed:
            L10n.datePlayed
        case .default:
            L10n.default
        case .indexNumber:
            L10n.indexNumber
        case .isFavoriteOrLiked:
            L10n.favorite
        case .isFolder:
            L10n.folder
        case .isPlayed:
            L10n.played
        case .isUnplayed:
            L10n.unplayed
        case .name:
            L10n.name
        case .officialRating:
            L10n.officialRating
        case .parentIndexNumber:
            L10n.parentIndexNumber
        case .playCount:
            L10n.playCount
        case .premiereDate:
            L10n.premiereDate
        case .productionYear:
            L10n.year
        case .random:
            L10n.random
        case .runtime:
            L10n.runtime
        case .seriesDatePlayed:
            L10n.seriesDatePlayed
        case .seriesSortName:
            L10n.seriesName
        case .sortName:
            L10n.sortName
        case .startDate:
            L10n.startDate
        case .studio:
            L10n.studio
        case .videoBitRate:
            L10n.videoBitRate
        }
    }

    /// All `ItemSortBy` cases supported in Swiftfin
    /// - This is the order displayed in `FilterView`s so order matters!
    static var supportedCases: [ItemSortBy] {
        [
            // Generic
            .name,
            .random,
            .sortName,

            // Dates
            .airTime,
            .dateCreated,
            .dateLastContentAdded,
            .datePlayed,
            .premiereDate,
            .startDate,

            // Ratings
            .communityRating,
            .criticRating,
            .officialRating,

            // Year
            .productionYear,

            // Episode / Series
            .airedEpisodeOrder,
            .indexNumber,
            .parentIndexNumber,
            .seriesSortName,

            // Music
            .album,
            .albumArtist,
            .artist,

            // Status
            .isFavoriteOrLiked,
            .isFolder,
            .isPlayed,
            .isUnplayed,

            // Stats
            .playCount,
            .runtime,
            .videoBitRate,

            // Other
            .studio
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
