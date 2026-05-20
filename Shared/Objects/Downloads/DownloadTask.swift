//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

enum DownloadState: Codable, Hashable {
    case queued
    case downloading
    case paused
    case error(DownloadError)
}

struct DownloadImage: Codable, Hashable {
    let kind: ImageType
    let relativePath: String
    let aspectRatio: CGFloat?
}

/// An in-flight download. The task is created when an item is queued and is
/// removed from `DownloadManager.tasks` once the transfer completes and the
/// item graduates to `DownloadManager.downloads`.
struct DownloadTask: Codable, Hashable, Identifiable, Storable {

    let id: String
    let itemJSON: Data

    var state: DownloadState
    var bytesDownloaded: Int64
    var bytesTotal: Int64
    var resumeData: Data?

    let createdAt: Date
    var updatedAt: Date

    var progress: Double {
        guard bytesTotal > 0 else { return 0 }
        return min(1, Double(bytesDownloaded) / Double(bytesTotal))
    }

    var downloadFolder: URL {
        item?.downloadFolder ?? URL.swiftfinDownloads.appendingPathComponent(id, isDirectory: true)
    }

    var imagesFolder: URL {
        downloadFolder.appendingPathComponent("Images", isDirectory: true)
    }

    var item: BaseItemDto? {
        try? JSONDecoder().decode(BaseItemDto.self, from: itemJSON)
    }
}

extension DownloadTask {

    init(item: BaseItemDto) throws {
        let json = try JSONEncoder().encode(item)
        let now = Date()
        self.init(
            id: item.id!,
            itemJSON: json,
            state: .queued,
            bytesDownloaded: 0,
            bytesTotal: 0,
            resumeData: nil,
            createdAt: now,
            updatedAt: now
        )
    }
}
