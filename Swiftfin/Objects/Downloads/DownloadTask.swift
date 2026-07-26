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

struct DownloadImage: Codable, Hashable {

    let pathKey: String
    let relativePath: String
    let aspectRatio: CGFloat?
}

struct DownloadTask: Codable, Hashable, Identifiable, Storable {

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
        guard let match = images.first(where: { $0.pathKey == serverURL.path }) else { return nil }
        return imagesFolder.appendingPathComponent(match.relativePath)
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

extension DownloadTask: Displayable, SystemImageable {

    var displayTitle: String {
        item.displayTitle
    }

    var systemImage: String {
        item.systemImage
    }
}
