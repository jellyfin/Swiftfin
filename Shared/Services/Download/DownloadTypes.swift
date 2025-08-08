//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// MARK: - Shared Data Structures

/// Represents the metadata for a downloaded item, including version information
struct DownloadMetadata: Codable {
    let itemId: String
    let itemType: String?
    let displayTitle: String
    // Full item payload merged into metadata.json; optional for backward compatibility
    var item: BaseItemDto?
    var versions: [VersionInfo]

    init(itemId: String, itemType: String?, displayTitle: String, item: BaseItemDto? = nil, versions: [VersionInfo] = []) {
        self.itemId = itemId
        self.itemType = itemType
        self.displayTitle = displayTitle
        self.item = item
        self.versions = versions
    }
}

/// Information about a specific version of a downloaded item
struct VersionInfo: Codable {
    let versionId: String
    let container: String
    let isStatic: Bool
    let mediaSourceId: String?
    let downloadDate: String
    let taskId: String

    init(
        versionId: String,
        container: String,
        isStatic: Bool,
        mediaSourceId: String?,
        downloadDate: String,
        taskId: String
    ) {
        self.versionId = versionId
        self.container = container
        self.isStatic = isStatic
        self.mediaSourceId = mediaSourceId
        self.downloadDate = downloadDate
        self.taskId = taskId
    }
}

// MARK: - Download Job Types

enum DownloadJobType: Hashable, Equatable {
    case media
    case backdropImage
    case primaryImage
    case metadata
    case subtitle(index: Int)
}

enum DownloadQuality: Hashable, Equatable {
    case original
    case high // 1080p, ~4 Mbps
    case medium // 720p, ~2 Mbps
    case low // 480p, ~1 Mbps
    case custom(TranscodingParameters)
}

struct TranscodingParameters: Hashable, Equatable {
    let maxWidth: Int?
    let maxHeight: Int?
    let videoBitRate: Int?
    let audioBitRate: Int?
    let enableAutoStreamCopy: Bool

    init(
        maxWidth: Int? = nil,
        maxHeight: Int? = nil,
        videoBitRate: Int? = nil,
        audioBitRate: Int? = nil,
        enableAutoStreamCopy: Bool = true
    ) {
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.videoBitRate = videoBitRate
        self.audioBitRate = audioBitRate
        self.enableAutoStreamCopy = enableAutoStreamCopy
    }

    static let highQuality = TranscodingParameters(
        maxWidth: 1920,
        maxHeight: 1080,
        videoBitRate: 4_000_000,
        audioBitRate: 128_000
    )

    static let mediumQuality = TranscodingParameters(
        maxWidth: 1280,
        maxHeight: 720,
        videoBitRate: 2_000_000,
        audioBitRate: 128_000
    )

    static let lowQuality = TranscodingParameters(
        maxWidth: 854,
        maxHeight: 480,
        videoBitRate: 1_000_000,
        audioBitRate: 96000
    )
}

struct DownloadJob {
    let type: DownloadJobType
    let taskID: UUID
    let url: URL
    let destinationPath: String
}

// MARK: - Error Types

enum MediaValidationError: Error, LocalizedError {
    case invalidHTTPStatus(Int)
    case unacceptableContentType(String?)
    case suspiciouslySmallFile(Int64)

    var errorDescription: String? {
        switch self {
        case let .invalidHTTPStatus(code):
            return "Invalid HTTP status: \(code)"
        case let .unacceptableContentType(type):
            return "Unacceptable content type: \(type ?? "unknown")"
        case let .suspiciouslySmallFile(size):
            return "Downloaded media file is too small (\(size) bytes)"
        }
    }
}

// MARK: - Service Protocols

protocol DownloadFileServicing {
    func ensureDownloadDirectory() throws
    func moveMediaFile(from temp: URL, to destination: URL, for task: DownloadTask, response: URLResponse?) throws
    func moveImageFile(from temp: URL, to destination: URL, for task: DownloadTask, response: URLResponse?, jobType: DownloadJobType) throws
    func validateMediaFile(at url: URL, response: URLResponse?) throws
    func calculateSize(of folder: URL) throws -> Int64
    func deleteDownloads(for itemId: String) throws -> Bool
    func deleteAllDownloads() throws
    func clearTmp()
    func checkAvailableDiskSpace() throws
    func hasMediaFile(for itemId: String, mediaSourceId: String?) -> Bool
    func getDownloadedItemIds() -> [String]
    func getTotalDownloadSize() -> Int64?
    func getDownloadSize(itemId: String) -> Int64?
    func isItemDownloaded(itemId: String) -> Bool
}

protocol DownloadURLBuilding {
    func mediaURL(
        itemId: String,
        quality: DownloadQuality,
        mediaSourceId: String?,
        container: String,
        isStatic: Bool,
        allowVideoStreamCopy: Bool,
        allowAudioStreamCopy: Bool,
        deviceId: String?,
        deviceProfileId: String?
    ) -> URL?

    func imageURL(for item: BaseItemDto, type: DownloadJobType) -> URL?
}

protocol DownloadMetadataManaging {
    func readMetadata(itemId: String) -> DownloadMetadata?
    func writeMetadata(for task: DownloadTask) throws
    func getDownloadedVersions(for itemId: String) -> [VersionInfo]
    func parseDownloadItem(with id: String) -> DownloadTask?

    // Debug methods
    func debugListDownloadedItems()
    func debugCheckSpecificVersion(itemId: String, mediaSourceId: String?)
}

protocol DownloadImageManaging {
    func downloadImages(for task: DownloadTask, completion: @escaping (Result<Void, Error>) -> Void)
}

protocol DownloadSessionManaging {
    var delegate: DownloadSessionDelegate? { get set }
    func start(url: URL, taskID: UUID, jobType: DownloadJobType) async throws
    func pause(taskID: UUID)
    func resume(taskID: UUID, with resumeData: Data?) async throws
    func cancel(taskID: UUID)
    func getAllTasks() -> [URLSessionDownloadTask]

    // Job management methods
    func getDownloadJob(for taskIdentifier: Int) -> DownloadJob?
    func removeDownloadJob(for taskIdentifier: Int)
}

// MARK: - Delegate Protocol

protocol DownloadSessionDelegate: AnyObject {
    func sessionDidCompleteDownload(taskIdentifier: Int, location: URL, response: URLResponse?)
    func sessionDidUpdateProgress(taskIdentifier: Int, progress: Double)
    func sessionDidCompleteWithError(taskIdentifier: Int, error: Error?)
    func sessionDidFinishBackgroundEvents()
}
