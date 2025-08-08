//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation

// MARK: - Download Services Factory Registration

extension Container {

    /// Refactored download services for better testability and separation of concerns

    var downloadManager: Factory<DownloadManager> {
        self {
            DownloadManager(
                sessionManager: self.downloadSessionManager(),
                urlBuilder: self.downloadURLBuilder(),
                metadataManager: self.downloadMetadataManager(),
                imageManager: self.downloadImageManager(),
                fileService: self.downloadFileService()
            )
        }.shared
    }

    var downloadSessionManager: Factory<DownloadSessionManaging> {
        self { DownloadSessionManager() }.shared
    }

    var downloadURLBuilder: Factory<DownloadURLBuilding> {
        self { DownloadURLBuilder() }.singleton
    }

    var downloadFileService: Factory<DownloadFileServicing> {
        self { DownloadFileService() }.shared
    }

    var downloadMetadataManager: Factory<DownloadMetadataManaging> {
        self {
            DownloadMetadataManager(fileService: self.downloadFileService())
        }.shared
    }

    var downloadImageManager: Factory<DownloadImageManaging> {
        self {
            DownloadImageManager(
                urlBuilder: self.downloadURLBuilder(),
                fileService: self.downloadFileService()
            )
        }.shared
    }
}
