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
    case completed(mediaRelativePath: String?)

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

enum DownloadKind: String, Codable, Hashable {

    case media
    case container
}

struct DownloadTask: Codable, Hashable, Identifiable, Storable {

    let id: String
    var item: BaseItemDto
    let kind: DownloadKind
    let parameters: DownloadParameters
    var parentIDs: [String]

    var state: DownloadState
    var bytesDownloaded: Int64
    var bytesTotal: Int64
    var resumeData: Data?

    let createdAt: Date

    var progress: Double {
        guard bytesTotal > 0 else { return 0 }
        return (Double(bytesDownloaded) / Double(bytesTotal)).clamped(to: 0 ... 1)
    }

    var downloadFolder: URL {
        item.downloadFolder ?? URL.swiftfinDownloads.appendingPathComponent(id, isDirectory: true)
    }

    var imagesFolder: URL {
        item.downloadImagesFolder ?? downloadFolder.appendingPathComponent("Images", isDirectory: true)
    }

    var subtitlesFolder: URL {
        downloadFolder.appendingPathComponent("Subtitles", isDirectory: true)
    }

    func localSubtitleURL(for stream: MediaStream) -> URL? {
        guard stream.type == .subtitle, let index = stream.index else { return nil }
        return subtitlesFolder.appendingPathComponent("\(index).\(stream.codec?.lowercased() ?? "srt")")
    }

    var isContainer: Bool {
        if case .container = kind { return true }
        return false
    }

    var isCompleted: Bool {
        if case .completed = state { return true }
        return false
    }

    var mediaRelativePath: String? {
        if case let .completed(path) = state { return path }
        return nil
    }

    var mediaURL: URL? {
        guard let mediaRelativePath else { return nil }
        return downloadFolder.appendingPathComponent(mediaRelativePath)
    }
}

extension DownloadTask {

    init(
        item: BaseItemDto,
        kind: DownloadKind = .media,
        parameters: DownloadParameters,
        parentIDs: [String] = []
    ) throws {
        guard let id = item.id else {
            throw ErrorMessage("Item has no id")
        }

        var item = item
        item.setDownloaded()

        self.init(
            id: id,
            item: item,
            kind: kind,
            parameters: parameters,
            parentIDs: parentIDs,
            state: .queued,
            bytesDownloaded: 0,
            bytesTotal: 0,
            resumeData: nil,
            createdAt: Date()
        )
    }
}

extension DownloadTask: Displayable {

    var displayTitle: String {
        item.displayTitle
    }
}
