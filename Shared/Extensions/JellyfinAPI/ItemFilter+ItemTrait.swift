//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// Aliased so the name `ItemFilter` can be repurposed.
///
/// - Important: Make sure to use the correct `filters` parameter for item calls!
typealias ItemTrait = JellyfinAPI.ItemFilter

extension ItemTrait: ItemFilter {

    var value: String {
        rawValue
    }

    init(from anyFilter: AnyItemFilter) {
        self.init(rawValue: anyFilter.value)!
    }
}

extension ItemTrait: Displayable {
    var displayTitle: String {
        switch self {
        case .isUnplayed:
            L10n.unplayed
        case .isPlayed:
            L10n.played
        case .isFavorite:
            L10n.favorites
        case .likes:
            L10n.likedItems
        default:
            .empty
        }
    }
}

extension ItemTrait: SupportedCaseIterable {

    static var supportedCases: [ItemTrait] {
        [
            .isUnplayed,
            .isPlayed,
            .isFavorite,
            .likes,
        ]
    }
}

extension UserItemDataDto {

    /// Missing fields cannot disqualify a partial response.
    func matches(_ filters: some Sequence<JellyfinAPI.ItemFilter>) -> Bool {
        filters.allSatisfy { filter in
            switch filter {
            case .isFavorite: isFavorite != false
            case .isPlayed: isPlayed != false
            case .isUnplayed: isPlayed != true
            case .isResumable: isPlayed != true && playbackPositionTicks != 0
            case .likes: isLikes != false
            case .dislikes: isLikes != true
            default: true
            }
        }
    }
}
