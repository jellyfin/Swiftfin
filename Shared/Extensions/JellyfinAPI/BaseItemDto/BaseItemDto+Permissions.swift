//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import JellyfinAPI
import SwiftUI

@MainActor
extension BaseItemDto {

    /// Indicates whether the item can be downloaded by the current user
    var canBeDownloaded: Bool {
        guard let userPolicy = dependency(\.currentUserSession)?.userData.policy else { return false }

        return userPolicy.enableContentDownloading == true && canDownload == true
    }

    /// Indicates whether the item's metadata can be edited by the current user
    var canEditMetadata: Bool {
        guard let userPolicy = dependency(\.currentUserSession)?.userData.policy else { return false }

        switch type {
        case .playlist:
            return canDelete == true
        case .boxSet:
            return userPolicy.enableCollectionManagement == true || userPolicy.isAdministrator == true
        default:
            return userPolicy.isAdministrator == true
        }
    }

    /// Indicates whether the item's lyrics can be edited by the current user
    var canEditLyrics: Bool {
        guard let userPolicy = dependency(\.currentUserSession)?.userData.policy else { return false }

        switch type {
        case .audio:
            return userPolicy.enableLyricManagement == true || userPolicy.isAdministrator == true
        default:
            return false
        }
    }

    /// Indicates whether the item's subtitles can be edited by the current user
    var canEditSubtitles: Bool {
        guard let userPolicy = dependency(\.currentUserSession)?.userData.policy else { return false }

        switch type {
        case .episode, .movie, .musicVideo, .trailer, .video:
            return userPolicy.enableSubtitleManagement == true || userPolicy.isAdministrator == true
        default:
            return false
        }
    }

    /// Can this `BaseItemDto` be played
    var presentPlayButton: Bool {
        guard dependency(\.currentUserSession)?.userData.policy?.enableMediaPlayback == true else { return false }

        switch type {
        case .audio, .audioBook, .book, .channel, .channelFolderItem, .episode,
             .movie, .liveTvChannel, .liveTvProgram, .musicAlbum, .musicArtist, .musicVideo, .playlist,
             .program, .recording, .season, .series, .trailer, .tvChannel, .tvProgram, .video:
            return true
        default:
            return false
        }
    }

    var canShuffle: Bool {
        guard id?.nilIfBlank != nil,
              !isMissing,
              dependency(\.currentUserSession)?.userData.policy?.enableMediaPlayback == true
        else { return false }

        switch type {
        case .series, .season, .boxSet:
            return true

        case .collectionFolder, .userView, .folder:
            switch collectionType {
            case .none, .movies, .tvshows, .boxsets, .homevideos, .musicvideos, .folders:
                return true
            default:
                return false
            }

        default:
            return false
        }
    }

    /// Can this `BaseItemDto` be recorded
    var canBeRecorded: Bool {
        guard dependency(\.currentUserSession)?.userData.policy?.enableLiveTvManagement == true else { return false }

        switch type {
        case .channel, .liveTvChannel, .tvChannel:
            return true
        case .program, .liveTvProgram, .tvProgram:
            return (endDate ?? .distantPast) > Date()
        default:
            return false
        }
    }
}
