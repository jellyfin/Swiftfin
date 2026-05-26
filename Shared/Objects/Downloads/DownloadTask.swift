//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

enum DownloadState: Codable, Hashable, Comparable {
    case queued
    case downloading
    case paused
    case error(DownloadError)
    case completed(completedAt: Date, mediaRelativePath: String?, images: [DownloadImage])

    private var rank: Int {
        switch self {
        case .downloading:
            0
        case .paused:
            1
        case .queued:
            2
        case .error:
            3
        case .completed:
            4
        }
    }

    static func < (lhs: DownloadState, rhs: DownloadState) -> Bool {
        lhs.rank < rhs.rank
    }
}

enum DownloadType: Hashable, Codable {
    case direct
    case transcode(PlaybackBitrate)
}

enum DownloadKind: Hashable, Codable {
    case media(DownloadType)
    case container
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
    let kind: DownloadKind
    let parentIDs: [String]

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

    var isContainer: Bool {
        if case .container = kind { return true }
        return false
    }

    var isCompleted: Bool {
        if case .completed = state { return true }
        return false
    }

    var completedAt: Date? {
        if case let .completed(date, _, _) = state { return date }
        return nil
    }

    var mediaRelativePath: String? {
        if case let .completed(_, path, _) = state { return path }
        return nil
    }

    var images: [DownloadImage] {
        if case let .completed(_, _, images) = state { return images }
        return []
    }

    var mediaURL: URL? {
        guard let mediaRelativePath else { return nil }
        return downloadFolder.appendingPathComponent(mediaRelativePath)
    }

    func localFileURL(for serverURL: URL) -> URL? {
        let images = images
        let path = serverURL.path
        if let match = images.first(where: { $0.pathKey == path }) {
            return imagesFolder.appendingPathComponent(match.relativePath)
        }
        if let last = serverURL.pathComponents.last,
           let kind = ImageType(rawValue: last.lowercased()),
           let match = images.first(where: { $0.pathKey == "legacy:\(kind.rawValue)" })
        {
            return imagesFolder.appendingPathComponent(match.relativePath)
        }
        return nil
    }
}

extension DownloadTask: Codable {

    private enum CodingKeys: String, CodingKey {
        case id
        case item
        case itemJSON
        case kind
        case type
        case parentIDs
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
        if let kind = try c.decodeIfPresent(DownloadKind.self, forKey: .kind) {
            self.kind = kind
        } else if let type = try c.decodeIfPresent(DownloadType.self, forKey: .type) {
            self.kind = .media(type)
        } else {
            self.kind = .media(.direct)
        }
        self.parentIDs = try c.decodeIfPresent([String].self, forKey: .parentIDs) ?? []
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
        try c.encode(kind, forKey: .kind)
        try c.encode(parentIDs, forKey: .parentIDs)
        try c.encode(state, forKey: .state)
        try c.encode(bytesDownloaded, forKey: .bytesDownloaded)
        try c.encode(bytesTotal, forKey: .bytesTotal)
        try c.encodeIfPresent(resumeData, forKey: .resumeData)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}

extension DownloadTask {

    init(
        item: BaseItemDto,
        kind: DownloadKind = .media(.direct),
        parentIDs: [String] = []
    ) throws {
        guard let id = item.id else {
            throw ErrorMessage("Item has no id")
        }
        let now = Date()
        self.init(
            id: id,
            item: item,
            kind: kind,
            parentIDs: parentIDs,
            state: .queued,
            bytesDownloaded: 0,
            bytesTotal: 0,
            resumeData: nil,
            createdAt: now,
            updatedAt: now
        )
    }
}

extension DownloadTask: Displayable, LibraryIdentifiable, SystemImageable {

    var displayTitle: String {
        item.displayTitle
    }

    var unwrappedIDHashOrZero: Int {
        id.hashValue
    }

    var systemImage: String {
        item.systemImage
    }
}

extension DownloadTask {

    var seasonEpisodeLabel: String? {
        item.seasonEpisodeLabel
    }

    var premiereDateYear: String? {
        item.premiereDateYear
    }

    var runTimeLabel: String? {
        item.runTimeLabel
    }

    var officialRating: String? {
        item.officialRating
    }

    func compare(to other: DownloadTask, by sort: ItemSortBy) -> Bool {
        switch sort {
        case .sortName, .name:
            (item.sortName ?? displayTitle) < (other.item.sortName ?? other.displayTitle)
        case .premiereDate:
            (item.premiereDate ?? .distantPast) < (other.item.premiereDate ?? .distantPast)
        case .productionYear:
            (item.productionYear ?? 0) < (other.item.productionYear ?? 0)
        case .dateCreated:
            (item.dateCreated ?? .distantPast) < (other.item.dateCreated ?? .distantPast)
        case .runtime:
            (item.runTimeTicks ?? 0) < (other.item.runTimeTicks ?? 0)
        case .communityRating:
            (item.communityRating ?? 0) < (other.item.communityRating ?? 0)
        case .criticRating:
            (item.criticRating ?? 0) < (other.item.criticRating ?? 0)
        default:
            (item.sortName ?? displayTitle) < (other.item.sortName ?? other.displayTitle)
        }
    }
}
