//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

struct CodingError: NetworkError {

    enum Reason {
        case decodingFailed
        case encodingFailed
        case invalidResponse
    }

    let reason: Reason
    let underlyingError: Error?

    var statusCode: Int? {
        nil
    }

    var displayTitle: String {
        L10n.codingError
    }

    var errorDescription: String? {
        switch reason {
        case .decodingFailed:
            return L10n.decodingFailed
        case .encodingFailed:
            return L10n.encodingFailed
        case .invalidResponse:
            return L10n.invalidResponse
        }
    }

    var recoverySuggestion: String? {
        L10n.validateVersionMessage
    }

    var systemImage: String {
        "square.3.layers.3d.down.right.slash"
    }

    var isRetryable: Bool {
        false
    }

    var retryAfter: TimeInterval? {
        nil
    }
}
