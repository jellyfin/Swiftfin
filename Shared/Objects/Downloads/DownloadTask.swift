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

struct DownloadImage: Hashable {

    let pathKey: String
    let relativePath: String
    let aspectRatio: CGFloat?

    let legacyKind: ImageType?

    init(pathKey: String, relativePath: String, aspectRatio: CGFloat?) {
        self.pathKey = pathKey
        self.relativePath = relativePath
        self.aspectRatio = aspectRatio
        self.legacyKind = nil
    }
}

extension DownloadImage: Codable {

    private enum CodingKeys: String, CodingKey {
        case pathKey
        case kind
        case relativePath
        case aspectRatio
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.legacyKind = try c.decodeIfPresent(ImageType.self, forKey: .kind)
        if let key = try c.decodeIfPresent(String.self, forKey: .pathKey) {
            self.pathKey = key
        } else if let kind = legacyKind {
            self.pathKey = "legacy:\(kind.rawValue)"
        } else {
            self.pathKey = ""
        }
        self.relativePath = try c.decode(String.self, forKey: .relativePath)
        self.aspectRatio = try c.decodeIfPresent(CGFloat.self, forKey: .aspectRatio)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(pathKey, forKey: .pathKey)
        try c.encode(relativePath, forKey: .relativePath)
        try c.encodeIfPresent(aspectRatio, forKey: .aspectRatio)
    }
}

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
