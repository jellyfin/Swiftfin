//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum DownloadError: Codable, Hashable, Displayable, Error {

    case cancelled
    case networkFailure
    case insufficientStorage
    case fileSystemError
    case unknown(String)

    // swiftlint:disable:next hard_coded_display_string
    var displayTitle: String {
        switch self {
        case .cancelled:
            "Download cancelled"
        case .networkFailure:
            "Network connection failed"
        case .insufficientStorage:
            "Not enough storage space"
        case .fileSystemError:
            "File system error"
        case let .unknown(message):
            message.isEmpty ? "Unknown error" : "Unknown error: \(message)"
        }
    }
}

extension DownloadError {

    init(_ error: Error) {
        if let downloadError = error as? DownloadError {
            self = downloadError
            return
        }

        let nsError = error as NSError

        switch nsError.domain {
        case NSURLErrorDomain:
            self = .networkFailure
        case NSPOSIXErrorDomain:
            self = .fileSystemError
        default:
            self = .unknown(nsError.localizedDescription)
        }
    }
}
