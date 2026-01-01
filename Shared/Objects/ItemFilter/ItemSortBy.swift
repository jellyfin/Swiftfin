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
            return L10n.default
        case .airedEpisodeOrder:
            return L10n.airedEpisodeOrder
        case .album:
            return L10n.album
        case .albumArtist:
            return L10n.albumArtist
        case .artist:
            return L10n.artist
        case .dateCreated:
            return L10n.dateCreated
        case .officialRating:
            return L10n.officialRating
        case .datePlayed:
            return L10n.datePlayed
        case .premiereDate:
            return L10n.premiereDate
        case .startDate:
            return L10n.startDate
        case .sortName:
            return L10n.sortName
        case .name:
            return L10n.name
        case .random:
            return L10n.random
        case .runtime:
            return L10n.runtime
        case .communityRating:
            return L10n.communityRating
        case .productionYear:
            return L10n.year
        case .playCount:
            return L10n.playCount
        case .criticRating:
            return L10n.criticRating
        case .isFolder:
            return L10n.folder
        case .isUnplayed:
            return L10n.unplayed
        case .isPlayed:
            return L10n.played
        case .seriesSortName:
            return L10n.seriesName
        case .videoBitRate:
            return L10n.videoBitRate
        case .airTime:
            return L10n.airTime
        case .studio:
            return L10n.studio
        case .isFavoriteOrLiked:
            return L10n.favorite
        case .dateLastContentAdded:
            return L10n.dateAdded
        case .seriesDatePlayed:
            return L10n.seriesDatePlayed
        case .parentIndexNumber:
            return L10n.parentIndexNumber
        case .indexNumber:
            return L10n.indexNumber
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
