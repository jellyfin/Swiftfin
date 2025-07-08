//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Unified error type for download-related operations
/// Consolidates error handling across APIClient and DownloadTask
enum DownloadError: Error, LocalizedError {

    // MARK: - Error Cases

    case invalidURL
    case httpError(Int)
    case noMediaSource
    case timeoutAfterRetries(Int)
    case networkConnectionLost
    case insufficientStorage
    case fileSystemError(String)
    case notEnoughStorage

    // MARK: - LocalizedError Implementation

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid download URL"
        case let .httpError(code):
            return "Server error (\(code)). Please try again later."
        case .noMediaSource:
            return "No media source available for download"
        case let .timeoutAfterRetries(retries):
            return "Download timed out after \(retries) attempts. Check your network connection and try again."
        case .networkConnectionLost:
            return "Network connection lost. Please check your internet connection and try again."
        case .insufficientStorage, .notEnoughStorage:
            return "Not enough storage space available to download this item."
        case let .fileSystemError(details):
            return "File system error: \(details)"
        }
    }

    var localizedDescription: String {
        errorDescription ?? "Unknown download error"
    }

    // MARK: - User-Friendly Messages

    var userFriendlyMessage: String {
        switch self {
        case .invalidURL:
            return "There was a problem with the download link. Please try refreshing and downloading again."
        case let .httpError(code):
            return "The server returned an error (\(code)). This usually resolves itself - please try again in a few minutes."
        case .noMediaSource:
            return "This content cannot be downloaded. It may not be available for offline viewing."
        case let .timeoutAfterRetries(retries):
            return "The download is taking too long, possibly due to a slow connection or large file size. The download was attempted \(retries) times. Try downloading during off-peak hours or check your network connection."
        case .networkConnectionLost:
            return "Your internet connection was interrupted. Please reconnect and try downloading again. Downloads can be resumed from where they left off."
        case .insufficientStorage, .notEnoughStorage:
            return "You don't have enough free space to download this content. Please delete some files or apps and try again."
        case let .fileSystemError(details):
            return "There was a problem accessing your device's storage: \(details). Please restart the app and try again."
        }
    }

    // MARK: - Retry Logic

    var isRetryable: Bool {
        switch self {
        case .invalidURL, .httpError, .timeoutAfterRetries, .networkConnectionLost, .fileSystemError:
            return true
        case .noMediaSource, .insufficientStorage, .notEnoughStorage:
            return false
        }
    }
}
