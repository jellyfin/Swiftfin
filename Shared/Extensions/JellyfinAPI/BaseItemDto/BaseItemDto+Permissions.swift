//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

extension BaseItemDto {

    /// Indicates whether the item can be downloaded by the current user
    var canBeDownloaded: Bool {
        guard let userPolicy = Container.shared.currentUserSession()?.user.data.policy else { return false }
        return userPolicy.enableContentDownloading == true && canDownload == true
    }

    /// Indicates whether the item's metadata can be edited by the current user
    var canEditMetadata: Bool {
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
        guard let userPolicy = Container.shared.currentUserSession()?.user.data.policy else { return false }

        switch type {
        case .episode, .movie, .musicVideo, .trailer, .video:
            return userPolicy.enableSubtitleManagement == true || userPolicy.isAdministrator == true
        default:
            return false
        }
    }

    /// Indicates whether the Editor Menu should be shown for the item
    var showEditorMenu: Bool {
        canEditMetadata
            || canEditSubtitles
        // TODO: Enable with Lyrics and/or Downloads
        // || canEditLyrics
        // || (!UIDevice.isTV && canBeDownloaded)
    }
}
