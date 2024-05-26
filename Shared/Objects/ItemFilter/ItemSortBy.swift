//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension ItemSortBy: Displayable {

    // TODO: only localize ones that we actually want
    
    var displayTitle: String {
        switch self {
        case .default:
            "Default"
        case .airedEpisodeOrder:
            "Aired Episode"
        case .album:
            "Album"
        case .albumArtist:
            "Album Artist"
        case .artist:
            "Artist"
        case .dateCreated:
            "Date Added"
        case .officialRating:
            "Official Rating"
        case .datePlayed:
            "Date Played"
        case .premiereDate:
            "Premiere Date"
        case .startDate:
            "Start Date"
        case .sortName:
            "Sort Name"
        case .name:
            "Name"
        case .random:
            "Random"
        case .runtime:
            "Runtime"
        case .communityRating:
            "Community Rating"
        case .productionYear:
            "Production Year"
        case .playCount:
            "Play Count"
        case .criticRating:
            "Critic Rating"
        case .isFolder:
            "Folder"
        case .isUnplayed:
            "Unplayed"
        case .isPlayed:
            "Played"
        case .seriesSortName:
            "Series"
        case .videoBitRate:
            "Video Bit Rate"
        case .airTime:
            "Air Time"
        case .studio:
            "Studio"
        case .isFavoriteOrLiked:
            "Favorite or Liked"
        case .dateLastContentAdded:
            "Last Content Added"
        case .seriesDatePlayed:
            "Series Date Played"
        case .parentIndexNumber:
            "Parent Index Number"
        case .indexNumber:
            "Index Number"
        case .similarityScore:
            "Similarity Score"
        case .searchScore:
            "Search Score"
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

extension ItemSortBy: SupportedCaseIterable {
    
    // TODO: add more
    static var supportedCases: [ItemSortBy] {
        [
            .premiereDate,
            .name,
            .dateCreated,
            .random
        ]
    }
}
