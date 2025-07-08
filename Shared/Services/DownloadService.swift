//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// Protocol defining the interface for download operations
/// Follows Single Responsibility Principle by focusing solely on download functionality
protocol DownloadService {

    // MARK: - Download Operations

    /// Downloads an item to the specified destination
    /// - Parameters:
    ///   - itemId: The unique identifier of the item to download
    ///   - destinationURL: The local URL where the item should be saved
    ///   - quality: The desired video quality for the download
    ///   - onProgress: Callback for download progress updates
    ///   - completion: Callback for download completion
    func downloadItem(
        itemId: String,
        destinationURL: URL,
        quality: VideoQuality,
        onProgress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    )

    /// Cancels an active download
    /// - Parameter itemId: The unique identifier of the item to cancel
    func cancelDownload(itemId: String)

    /// Resumes a previously interrupted download
    /// - Parameters:
    ///   - itemId: The unique identifier of the item to resume
    ///   - resumeData: The resume data from a previous download attempt
    ///   - destinationURL: The local URL where the item should be saved
    ///   - onProgress: Callback for download progress updates
    ///   - completion: Callback for download completion
    func resumeDownload(
        itemId: String,
        resumeData: Data,
        destinationURL: URL,
        onProgress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    )

    // MARK: - Download Management

    /// Gets the current download progress for an item
    /// - Parameter itemId: The unique identifier of the item
    /// - Returns: The current progress as a value between 0.0 and 1.0, or nil if not downloading
    func getDownloadProgress(for itemId: String) -> Double?

    /// Checks if an item is currently being downloaded
    /// - Parameter itemId: The unique identifier of the item
    /// - Returns: True if the item is currently downloading
    func isDownloading(itemId: String) -> Bool

    /// Gets all active download tasks
    /// - Returns: Array of active download task identifiers
    func getActiveDownloads() -> [String]

    // MARK: - Storage Management

    /// Checks if there's sufficient storage space for a download
    /// - Parameters:
    ///   - fileSize: The size of the file to download in bytes
    ///   - bufferPercentage: Additional buffer percentage (default 20%)
    /// - Returns: True if there's sufficient storage space
    func hasSufficientStorage(for fileSize: Int64, bufferPercentage: Double) -> Bool

    /// Gets the available storage space
    /// - Returns: Available storage space in bytes
    func getAvailableStorage() -> Int64
}

// MARK: - Default Implementation

extension DownloadService {

    func hasSufficientStorage(for fileSize: Int64, bufferPercentage: Double = 0.2) -> Bool {
        let requiredSpace = Int64(Double(fileSize) * (1.0 + bufferPercentage))
        return getAvailableStorage() >= requiredSpace
    }

    func getAvailableStorage() -> Int64 {
        #if os(iOS)
        return FileManager.default.availableStorage
        #else
        // For non-iOS platforms, return a large value to indicate sufficient space
        return Int64.max
        #endif
    }
}
