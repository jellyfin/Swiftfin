//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum DownloadError: Codable, Hashable, Displayable, Error {

    case networkFailure
    case insufficientStorage
    case fileSystemError
    case unknown(String)

    var displayTitle: String {
        switch self {
        case .networkFailure:
            L10n.networkConnectionFailed
        case .insufficientStorage:
            L10n.notEnoughStorage
        case .fileSystemError:
            L10n.fileSystemError
        case let .unknown(message):
            message.isEmpty ? L10n.unknownError : message
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
