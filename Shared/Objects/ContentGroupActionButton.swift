//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum ContentGroupActionButton: String, CaseIterable, Displayable, Equatable, Identifiable, Storable, SystemImageable {

    case played
    case favorited
    case trailers
    case playback
    case subtitles
    case refresh
    #if os(tvOS)
    case delete
    #else
    case editMetadata
    #endif

    var displayTitle: String {
        switch self {
        case .played:
            L10n.played
        case .favorited:
            L10n.favorited
        case .trailers:
            L10n.trailers
        case .playback:
            L10n.playback
        case .refresh:
            L10n.refreshMetadata
        case .subtitles:
            L10n.subtitles
        #if os(tvOS)
        case .delete:
            L10n.delete
        #else
        case .editMetadata:
            L10n.edit
        #endif
        }
    }

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .played:
            "checkmark"
        case .favorited:
            "heart.fill"
        case .trailers:
            "movieclapper"
        case .playback:
            "list.and.film"
        case .refresh:
            "arrow.clockwise"
        case .subtitles:
            "captions.bubble"
        #if os(tvOS)
        case .delete:
            "trash"
        #else
        case .editMetadata:
            "pencil"
        #endif
        }
    }

    var secondarySystemImage: String {
        switch self {
        case .favorited:
            "heart"
        default:
            systemImage
        }
    }

    var activeColor: Color? {
        switch self {
        case .played:
            .jellyfinPurple
        case .favorited:
            .pink
        default:
            nil
        }
    }

    static let defaultBarActionButtons: [ContentGroupActionButton] = [
        .played,
        .favorited,
        .trailers,
        .playback
    ]

    static let defaultMenuActionButtons: [ContentGroupActionButton] = [
        .subtitles,
        .refresh,
    ]
    #if os(tvOS)
    .appending(.delete)
    #else
    .appending(.editMetadata)
    #endif
}
