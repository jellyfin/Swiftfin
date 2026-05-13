//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

enum DownloadState: String, Codable, Hashable {
    case queued
    case downloading
    case paused
    case complete
    case error
}

struct DownloadImage: Codable, Hashable {
    let kind: ImageType
    let relativePath: String
    let aspectRatio: CGFloat?
}

struct DownloadRecord: Codable, Hashable, Identifiable {

    let id: String
    let itemJSON: Data

    var state: DownloadState
    var bytesDownloaded: Int64
    var bytesTotal: Int64
    var resumeData: Data?
    var mediaRelativePath: String?
    var images: [DownloadImage]

    let createdAt: Date
    var updatedAt: Date

    var progress: Double {
        guard bytesTotal > 0 else { return 0 }
        return min(1, Double(bytesDownloaded) / Double(bytesTotal))
    }

    /// On-disk location, derived from `BaseItemDto.downloadFolder` so we
    /// don't duplicate the per-kind path logic.
    var downloadFolder: URL {
        item?.downloadFolder ?? URL.swiftfinDownloads.appendingPathComponent(id, isDirectory: true)
    }

    var imagesFolder: URL {
        downloadFolder.appendingPathComponent("Images", isDirectory: true)
    }

    func imageURL(for kind: ImageType) -> URL? {
        guard let image = images.first(where: { $0.kind == kind }) else { return nil }
        return imagesFolder.appendingPathComponent(image.relativePath)
    }

    var item: BaseItemDto? {
        try? JSONDecoder().decode(BaseItemDto.self, from: itemJSON)
    }
}

extension DownloadRecord {

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
            mediaRelativePath: nil,
            images: [],
            createdAt: now,
            updatedAt: now
        )
    }
}

extension DownloadRecord: Storable {}
