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

extension BaseItemDto {

    /// Indicates whether the item can be downloaded by the current user
    var canBeDownloaded: Bool {
        guard let userPolicy = Container.shared.currentUserSession()?.user.data.policy,
              userPolicy.enableContentDownloading == true
        else { return false }

        switch type {
        case .boxSet, .person, .season, .series:
            return true
        default:
            return canDownload == true
        }
    }

    /// Indicates whether the item's metadata can be edited by the current user
    var canEditMetadata: Bool {
        guard !isDownloaded else { return false }
        guard let userPolicy = Container.shared.currentUserSession()?.user.data.policy else { return false }

        switch type {
        case .playlist:
            return canDelete == true
        case .boxSet:
            return (userPolicy.enableCollectionManagement == true || userPolicy.isAdministrator == true)
                && StoredValues[.User.enableCollectionManagement]
        default:
            return userPolicy.isAdministrator == true
                && StoredValues[.User.enableItemEditing]
        }
    }

    /// Indicates whether the item's lyrics can be edited by the current user
    var canEditLyrics: Bool {
        guard !isDownloaded else { return false }
        guard let userPolicy = Container.shared.currentUserSession()?.user.data.policy else { return false }

        switch type {
        case .audio:
            return userPolicy.enableLyricManagement == true || userPolicy.isAdministrator == true
        default:
            return false
        }
    }

    /// Indicates whether the item's subtitles can be edited by the current user
    var canEditSubtitles: Bool {
        guard !isDownloaded else { return false }
        guard let userPolicy = Container.shared.currentUserSession()?.user.data.policy else { return false }

        switch type {
        case .episode, .movie, .musicVideo, .trailer, .video:
            return userPolicy.enableSubtitleManagement == true || userPolicy.isAdministrator == true
        default:
            return false
        }
    }

    /// Indicates whether the item can be deleted by the current user
    var canDeleteItem: Bool {
        guard !isDownloaded else { return false }

        switch type {
        case .boxSet:
            return StoredValues[.User.enableCollectionManagement] && canDelete == true
        default:
            return StoredValues[.User.enableItemDeletion] && canDelete == true
        }
    }

    /// Indicates whether the Editor Menu should be shown for the item
    var canEdit: Bool {
        canEditMetadata
            || canEditSubtitles
        // TODO: Enable with Lyrics
        // || canEditLyrics
    }
}
