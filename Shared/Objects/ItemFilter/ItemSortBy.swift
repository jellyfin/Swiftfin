//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension ItemSortBy: Displayable, SupportedCaseIterable, AssociatedCaseIterable {

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

    /// Supported `BaseItemKind`s for each `ItemSortBy`.
    @ArrayBuilder<BaseItemKind>
    var applicableTypes: [BaseItemKind] {
        switch self {
        case .airTime, .startDate:
            BaseItemKind.program
            BaseItemKind.tvChannel
        case .album:
            BaseItemKind.audio
            BaseItemKind.musicAlbum
            BaseItemKind.musicVideo
            BaseItemKind.photo
        case .albumArtist:
            BaseItemKind.audio
            BaseItemKind.musicAlbum
            BaseItemKind.musicArtist
        case .artist:
            BaseItemKind.audio
            BaseItemKind.musicAlbum
            BaseItemKind.musicArtist
            BaseItemKind.musicVideo
        case .communityRating:
            BaseItemKind.book
            BaseItemKind.boxSet
            BaseItemKind.episode
            BaseItemKind.movie
            BaseItemKind.musicAlbum
            BaseItemKind.musicArtist
            BaseItemKind.program
            BaseItemKind.series
            BaseItemKind.tvChannel
        case .criticRating:
            BaseItemKind.boxSet
            BaseItemKind.episode
            BaseItemKind.movie
            BaseItemKind.musicAlbum
            BaseItemKind.series
        case .dateCreated:
            BaseItemKind.audio
            BaseItemKind.book
            BaseItemKind.boxSet
            BaseItemKind.collectionFolder
            BaseItemKind.episode
            BaseItemKind.folder
            BaseItemKind.movie
            BaseItemKind.musicAlbum
            BaseItemKind.musicArtist
            BaseItemKind.musicVideo
            BaseItemKind.photo
            BaseItemKind.photoAlbum
            BaseItemKind.playlist
            BaseItemKind.season
            BaseItemKind.series
            BaseItemKind.userView
        case .dateLastContentAdded:
            BaseItemKind.boxSet
            BaseItemKind.collectionFolder
            BaseItemKind.folder
            BaseItemKind.playlist
            BaseItemKind.season
            BaseItemKind.series
            BaseItemKind.userView
        case .datePlayed:
            BaseItemKind.audio
            BaseItemKind.book
            BaseItemKind.episode
            BaseItemKind.movie
            BaseItemKind.musicVideo
        case .indexNumber:
            BaseItemKind.episode
            BaseItemKind.season
        case .isFavoriteOrLiked:
            BaseItemKind.audio
            BaseItemKind.book
            BaseItemKind.boxSet
            BaseItemKind.episode
            BaseItemKind.movie
            BaseItemKind.musicAlbum
            BaseItemKind.musicArtist
            BaseItemKind.musicVideo
            BaseItemKind.photo
            BaseItemKind.photoAlbum
            BaseItemKind.playlist
            BaseItemKind.series
            BaseItemKind.video
        case .isFolder:
            BaseItemKind.collectionFolder
            BaseItemKind.folder
            BaseItemKind.photo
            BaseItemKind.userView
        case .isPlayed, .isUnplayed:
            BaseItemKind.audio
            BaseItemKind.book
            BaseItemKind.episode
            BaseItemKind.movie
            BaseItemKind.musicVideo
            BaseItemKind.video
        case .officialRating:
            BaseItemKind.book
            BaseItemKind.boxSet
            BaseItemKind.episode
            BaseItemKind.movie
            BaseItemKind.program
            BaseItemKind.series
            BaseItemKind.tvChannel
        case .playCount:
            BaseItemKind.audio
            BaseItemKind.episode
            BaseItemKind.movie
            BaseItemKind.musicVideo
        case .premiereDate:
            BaseItemKind.episode
            BaseItemKind.movie
            BaseItemKind.musicAlbum
            BaseItemKind.season
            BaseItemKind.series
        case .productionYear:
            BaseItemKind.book
            BaseItemKind.movie
            BaseItemKind.musicAlbum
            BaseItemKind.musicVideo
            BaseItemKind.season
            BaseItemKind.series
        case .runtime:
            BaseItemKind.audio
            BaseItemKind.episode
            BaseItemKind.movie
            BaseItemKind.musicVideo
            BaseItemKind.playlist
        case .seriesSortName, .airedEpisodeOrder, .parentIndexNumber:
            BaseItemKind.episode
        case .studio:
            BaseItemKind.boxSet
            BaseItemKind.episode
            BaseItemKind.movie
            BaseItemKind.series
        case .videoBitRate:
            BaseItemKind.episode
            BaseItemKind.movie
            BaseItemKind.musicVideo
            BaseItemKind.video
        case .name, .random, .sortName:
            [BaseItemKind]() // Available to all `BaseItemKind`
        default:
            [] // Available to no `BaseItemKind`
        }
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
