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

enum DownloadType: Hashable, Codable {
    case direct
    case transcode(PlaybackBitrate)
}

struct DownloadImage: Hashable {

    let pathKey: String
    let relativePath: String
    let aspectRatio: CGFloat?
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
        if let key = try c.decodeIfPresent(String.self, forKey: .pathKey) {
            self.pathKey = key
        } else if let kind = try c.decodeIfPresent(ImageType.self, forKey: .kind) {
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

struct DownloadTask: Hashable, Identifiable, Storable {

    let id: String
    let item: BaseItemDto
    let type: DownloadType

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
        item.downloadFolder ?? URL.swiftfinDownloads.appendingPathComponent(id, isDirectory: true)
    }

    var imagesFolder: URL {
        downloadFolder.appendingPathComponent("Images", isDirectory: true)
    }
}

extension DownloadTask: Codable {

    private enum CodingKeys: String, CodingKey {
        case id
        case item
        case itemJSON
        case type
        case state
        case bytesDownloaded
        case bytesTotal
        case resumeData
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        if let item = try c.decodeIfPresent(BaseItemDto.self, forKey: .item) {
            self.item = item
        } else if let json = try c.decodeIfPresent(Data.self, forKey: .itemJSON) {
            self.item = try JSONDecoder().decode(BaseItemDto.self, from: json)
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.item,
                .init(codingPath: decoder.codingPath, debugDescription: "DownloadTask is missing item")
            )
        }
        self.type = try c.decodeIfPresent(DownloadType.self, forKey: .type) ?? .direct
        self.state = try c.decode(DownloadState.self, forKey: .state)
        self.bytesDownloaded = try c.decode(Int64.self, forKey: .bytesDownloaded)
        self.bytesTotal = try c.decode(Int64.self, forKey: .bytesTotal)
        self.resumeData = try c.decodeIfPresent(Data.self, forKey: .resumeData)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(item, forKey: .item)
        try c.encode(type, forKey: .type)
        try c.encode(state, forKey: .state)
        try c.encode(bytesDownloaded, forKey: .bytesDownloaded)
        try c.encode(bytesTotal, forKey: .bytesTotal)
        try c.encodeIfPresent(resumeData, forKey: .resumeData)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}

extension DownloadTask {

    init(item: BaseItemDto, type: DownloadType = .direct) throws {
        guard let id = item.id else {
            throw ErrorMessage("Item has no id")
        }
        let now = Date()
        self.init(
            id: id,
            item: item,
            type: type,
            state: .queued,
            bytesDownloaded: 0,
            bytesTotal: 0,
            resumeData: nil,
            createdAt: now,
            updatedAt: now
        )
    }
}
