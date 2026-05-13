//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum DownloadError: Hashable, Displayable, Error {
    case cancelled
    case networkFailure
    case insufficientStorage
    case fileSystemError
    case unknown(String)

    var displayTitle: String {
        switch self {
        case .networkFailure:
            "Network connection failed"
        case .insufficientStorage:
            "Not enough storage space"
        case .fileSystemError:
            "File system error"
        case .cancelled:
            "Download cancelled"
        case let .unknown(message):
            message.isEmpty ? "Unknown error" : "Unknown error: \(message)"
        }
    }
}

extension DownloadError: Codable {

    private enum CodingKeys: String, CodingKey {
        case type
        case message
    }

    private enum ErrorType: String, Codable {
        case cancelled
        case networkFailure
        case insufficientStorage
        case fileSystemError
        case unknown
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ErrorType.self, forKey: .type)

        switch type {
        case .cancelled:
            self = .cancelled
        case .networkFailure:
            self = .networkFailure
        case .insufficientStorage:
            self = .insufficientStorage
        case .fileSystemError:
            self = .fileSystemError
        case .unknown:
            let message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
            self = .unknown(message)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .cancelled:
            try container.encode(ErrorType.cancelled, forKey: .type)
        case .networkFailure:
            try container.encode(ErrorType.networkFailure, forKey: .type)
        case .insufficientStorage:
            try container.encode(ErrorType.insufficientStorage, forKey: .type)
        case .fileSystemError:
            try container.encode(ErrorType.fileSystemError, forKey: .type)
        case let .unknown(message):
            try container.encode(ErrorType.unknown, forKey: .type)
            try container.encode(message, forKey: .message)
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
