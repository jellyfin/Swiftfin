//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// A pure data model representing a download task
struct DownloadTask {

    enum DownloadError: Error {

        case notEnoughStorage

        var localizedDescription: String {
            switch self {
            case .notEnoughStorage:
                return "Not enough storage"
            }
        }
    }

    enum State {

        case cancelled
        case complete
        case downloading(Double)
        case error(Error)
        case paused
        case ready
    }

    let item: BaseItemDto

    // Enhanced API properties
    let taskID: UUID
    let mediaSourceId: String?
    let versionId: String?
    let container: String
    let isStatic: Bool
    let allowVideoStreamCopy: Bool
    let allowAudioStreamCopy: Bool
    let deviceId: String?
    let deviceProfileId: String?
    let quality: DownloadQuality

    // Pause/Resume support
    var resumeData: Data?

    // Retry logic
    var retryCount: Int = 0
    let maxRetries: Int = 3

    // For TV series episodes
    var season: Int? {
        item.parentIndexNumber
    }

    var episodeID: String? {
        guard item.type == .episode else { return nil }
        return item.id
    }

    var imagesFolder: URL? {
        item.downloadFolder?.appendingPathComponent("Images")
    }

    var metadataFolder: URL? {
        item.downloadFolder?.appendingPathComponent("Metadata")
    }

    init(
        item: BaseItemDto,
        taskID: UUID = UUID(),
        mediaSourceId: String? = nil,
        versionId: String? = nil,
        container: String = "mp4",
        quality: DownloadQuality = .original,
        isStatic: Bool = true,
        allowVideoStreamCopy: Bool = true,
        allowAudioStreamCopy: Bool = true,
        deviceId: String? = nil,
        deviceProfileId: String? = nil
    ) {
        self.item = item
        self.taskID = taskID
        self.mediaSourceId = mediaSourceId
        self.versionId = versionId
        self.container = container
        self.quality = quality
        self.isStatic = isStatic
        self.allowVideoStreamCopy = allowVideoStreamCopy
        self.allowAudioStreamCopy = allowAudioStreamCopy
        self.deviceId = deviceId
        self.deviceProfileId = deviceProfileId
    }

    func shouldRetry(for error: Error) -> Bool {
        guard retryCount < maxRetries else { return false }

        // Check if error is retryable
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost:
                return true
            default:
                return false
            }
        }

        return false
    }

    mutating func incrementRetryCount() {
        retryCount += 1
    }

    mutating func resetRetryCount() {
        retryCount = 0
    }

    func encodeMetadata() -> Data {
        try! JSONEncoder().encode(item)
    }
}

extension DownloadTask: Identifiable {

    var id: UUID {
        taskID
    }
}
