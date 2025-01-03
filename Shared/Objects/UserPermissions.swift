//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct UserPermissions {

    let isAdministrator: Bool
    let items: UserItemPermissions

    init(_ policy: UserPolicy?) {
        self.isAdministrator = policy?.isAdministrator ?? false
        self.items = UserItemPermissions(policy, isAdministrator: isAdministrator)
    }

    struct UserItemPermissions {

        let canDelete: Bool
        let canDownload: Bool
        let canEditMetadata: Bool
        let canManageSubtitles: Bool
        let canManageCollections: Bool
        let canManageLyrics: Bool

        init(_ policy: UserPolicy?, isAdministrator: Bool) {
            self.canDelete = policy?.enableContentDeletion ?? false || policy?.enableContentDeletionFromFolders != []
            self.canDownload = policy?.enableContentDownloading ?? false
            self.canEditMetadata = isAdministrator
            // TODO: SDK 10.9 Enable Comments
            self.canManageSubtitles = isAdministrator // || policy?.enableSubtitleManagement ?? false
            self.canManageCollections = isAdministrator // || policy?.enableCollectionManagement ?? false
            // TODO: SDK 10.10 Enable Comments
            self.canManageLyrics = isAdministrator // || policy?.enableSubtitleManagement ?? false
        }
    }
}
