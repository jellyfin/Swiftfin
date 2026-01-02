//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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
        /// This user has server permissions to delete items
        let canDelete: Bool
        /// This user has server permissions to download items
        let canDownload: Bool
        /// This user has server permissions to edit items' metadata
        let canEditMetadata: Bool
        /// This user has server permissions to edit items' subtitles
        let canManageSubtitles: Bool
        /// This user has server permissions to edit collection
        let canManageCollections: Bool
        /// This user has server permissions to edit items' lyrics
        let canManageLyrics: Bool

        init(_ policy: UserPolicy?, isAdministrator: Bool) {
            self.canDelete = policy?.enableContentDeletion ?? false || policy?.enableContentDeletionFromFolders != []
            self.canDownload = policy?.enableContentDownloading ?? false
            self.canEditMetadata = isAdministrator
            self.canManageSubtitles = isAdministrator || policy?.enableSubtitleManagement ?? false
            self.canManageCollections = isAdministrator || policy?.enableCollectionManagement ?? false
            self.canManageLyrics = isAdministrator || policy?.enableSubtitleManagement ?? false
        }

        // MARK: - Item Specific Validation

        /// Does this user have permission to delete this item?
        func canDelete(item: BaseItemDto) -> Bool {
            switch item.type {
            case .playlist:
                /// Playlists can only be edited by owners who can also delete
                return item.canDelete == true
            case .boxSet:
                return canManageCollections
                    && StoredValues[.User.enableCollectionManagement]
                    && item.canDelete == true
            default:
                return canDelete
                    && StoredValues[.User.enableItemDeletion]
                    && item.canDelete == true
            }
        }

        /// Does this user have permission to download this item?
        func canDownload(item: BaseItemDto) -> Bool {
            canDownload && item.canDownload == true
        }

        /// Does this user have permission to edit this item's metadata?
        func canEditMetadata(item: BaseItemDto) -> Bool {
            switch item.type {
            case .playlist:
                /// Playlists can only be edited by owners who can also delete
                return item.canDelete == true
            case .boxSet:
                return (canManageCollections || canEditMetadata)
                    && StoredValues[.User.enableCollectionManagement]
            default:
                return canEditMetadata
                    && StoredValues[.User.enableItemEditing]
            }
        }

        /// Does this user have permission to edit this item's subtitles?
        func canManageSubtitles(item: BaseItemDto) -> Bool {
            switch item.type {
            case .episode, .movie, .musicVideo, .trailer, .video:
                return (canManageSubtitles || canEditMetadata)
                    && StoredValues[.User.enableItemEditing]
            default:
                return false
            }
        }

        /// Does this user have permission to edit this item's lyrics?
        func canManageLyrics(item: BaseItemDto) -> Bool {
            switch item.type {
            case .audio:
                return (canManageLyrics || canEditMetadata)
                    && StoredValues[.User.enableItemEditing]
            default:
                return false
            }
        }
    }
}
