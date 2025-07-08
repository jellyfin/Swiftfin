//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Centralized constants for download functionality
/// Follows Single Responsibility Principle by managing only configuration values
enum DownloadConstants {

    // MARK: - Timeouts

    /// Request timeout for download operations (2 minutes)
    static let requestTimeout: TimeInterval = 120.0

    /// Resource timeout for complete downloads (2 hours)
    static let resourceTimeout: TimeInterval = 7200.0

    // MARK: - Storage

    /// Default buffer percentage for storage calculations (20%)
    static let defaultStorageBuffer: Double = 0.2

    /// Minimum file size threshold for corruption detection (1MB)
    static let minimumFileSize: Int64 = 1024 * 1024

    // MARK: - File Management

    /// Default media filename
    static let defaultMediaFilename = "Media"

    /// Images folder name
    static let imagesFolderName = "Images"

    /// Metadata folder name
    static let metadataFolderName = "Metadata"

    /// Metadata filename
    static let metadataFilename = "Item.json"

    /// Primary image filename
    static let primaryImageFilename = "Primary"

    /// Backdrop image filename
    static let backdropImageFilename = "Backdrop"

    // MARK: - Session Configuration

    /// Background session identifier prefix
    static let sessionIdentifierPrefix = "bg-download-"

    /// UserDefaults key for download filename storage
    static let downloadFilenameKeyPrefix = "download_"

    /// UserDefaults key for floating indicator position
    static let floatingIndicatorPositionKey = "FloatingDownloadIndicatorPosition"

    // MARK: - Supported Video Extensions

    /// Supported video file extensions for media detection
    static let supportedVideoExtensions: [String] = [
        "mp4", "mkv", "mov", "avi", "m4v", "webm", "ogv", "wmv", "flv", "ts", "m2ts",
    ]

    // MARK: - Retry Configuration

    /// Maximum number of retry attempts for failed downloads
    static let maxRetryAttempts = 3

    /// Delay between retry attempts (seconds)
    static let retryDelay: TimeInterval = 5.0

    // MARK: - Platform Support

    /// Whether downloads are supported on the current platform
    static var isSupported: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }
}
