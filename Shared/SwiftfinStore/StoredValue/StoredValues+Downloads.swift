//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension StoredValues.Keys {

    enum Downloads {

        static func all(userID: String) -> Key<[DownloadTask]> {
            UserKey(
                ownerID: userID,
                field: "downloads",
                default: []
            )
        }

        private static func legacyTasks(userID: String) -> Key<[DownloadTask]> {
            UserKey(
                ownerID: userID,
                field: "downloadTasks",
                default: []
            )
        }

        private static func legacyItems(userID: String) -> Key<[LegacyDownloadItem]> {
            UserKey(
                ownerID: userID,
                field: "downloadedItems",
                default: []
            )
        }

        static func loadAndMigrate(userID: String) -> [DownloadTask] {
            let existing = StoredValues[all(userID: userID)]
            if existing.isNotEmpty { return existing }

            let legacyActive = StoredValues[legacyTasks(userID: userID)]
            let legacyCompleted = StoredValues[legacyItems(userID: userID)].map(\.asDownloadTask)

            let merged = legacyActive + legacyCompleted
            guard merged.isNotEmpty else { return [] }

            StoredValues[all(userID: userID)] = merged
            StoredValues[legacyTasks(userID: userID)] = []
            StoredValues[legacyItems(userID: userID)] = []
            return merged
        }
    }
}

private struct LegacyDownloadItem: Codable, Storable {

    let id: String
    let item: BaseItemDto
    let mediaRelativePath: String
    let images: [DownloadImage]
    let completedAt: Date

    var asDownloadTask: DownloadTask {
        DownloadTask(
            id: id,
            item: item,
            type: .direct,
            state: .completed(
                completedAt: completedAt,
                mediaRelativePath: mediaRelativePath,
                images: images
            ),
            bytesDownloaded: 0,
            bytesTotal: 0,
            resumeData: nil,
            createdAt: completedAt,
            updatedAt: completedAt
        )
    }
}
