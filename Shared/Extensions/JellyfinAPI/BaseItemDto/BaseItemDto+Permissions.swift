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

    /// Can this `BaseItemDto` be deleted by this user
    var canBeDeleted: Bool {
        guard let userPolicy = Container.shared.currentUserSession()?.user.data.policy else { return false }

        switch type {
        case .playlist:
            return canDelete == true
        case .boxSet:
            return userPolicy.isAdministrator == true
                && StoredValues[.User.enableCollectionManagement]
                && canDelete == true
        default:
            return userPolicy.isAdministrator == true
                && StoredValues[.User.enableItemDeletion]
                && canDelete == true
        }
    }

    /// Can this `BaseItemDto` be downloaded by this user
    var canBeDownloaded: Bool {
        guard let userPolicy = Container.shared.currentUserSession()?.user.data.policy else { return false }
        return userPolicy.enableContentDownloading == true && canDownload == true
    }

    /// Can this `BaseItemDto`'s metadata be edited by this user
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

    /// Can this `BaseItemDto`'s lyrics be edited by this user
    var canEditLyrics: Bool {
        guard let userPolicy = Container.shared.currentUserSession()?.user.data.policy else { return false }

        switch type {
        case .audio:
            return userPolicy.enableLyricManagement == true || userPolicy.isAdministrator == true
        default:
            return false
        }
    }

    /// Can this `BaseItemDto`'s subtitles be edited by this user
    var canEditSubtitles: Bool {
        guard let userPolicy = Container.shared.currentUserSession()?.user.data.policy else { return false }

        switch type {
        case .episode, .movie, .musicVideo, .trailer, .video:
            return userPolicy.enableSubtitleManagement == true || userPolicy.isAdministrator == true
        default:
            return false
        }
    }

    /// Is there an editor permission that necessates that the Editor Menu is shown
    var showEditorMenu: Bool {
        canEditMetadata
            || canEditSubtitles
            || canBeDeleted
        // TODO: Enable with Lyrics and/or Downloads
        // || canEditLyrics
        // || (!UIDevice.isTV && canBeDownloaded)
    }
}
