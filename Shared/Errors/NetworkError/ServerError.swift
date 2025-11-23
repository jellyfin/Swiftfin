//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

struct ServerError: NetworkError {

    let statusCode: Int?
    let retryAfterSeconds: Int?

    init(statusCode: Int, retryAfterSeconds: Int? = nil) {
        self.statusCode = statusCode
        self.retryAfterSeconds = retryAfterSeconds
    }

    var displayTitle: String {
        L10n.server
    }

    var errorDescription: String? {
        switch statusCode {
        case 503:
            return L10n.serviceUnavailable
        default:
            if let statusCode {
                return L10n.unknownNetworkError(statusCode)
            } else {
                return L10n.unknownError
            }
        }
    }

    var recoverySuggestion: String? {
        if let retryAfterSeconds {
            return L10n.serverStartingRetrySeconds(retryAfterSeconds)
        }

        switch statusCode {
        case 503:
            return L10n.serverStartingRetryLater
        default:
            return L10n.tryLaterOrContactAdmin
        }
    }

    var systemImage: String {
        "square.3.layers.3d.slash"
    }

    var isRetryable: Bool {
        true
    }

    var retryAfter: TimeInterval? {
        guard let retryAfterSeconds else { return nil }
        return TimeInterval(retryAfterSeconds)
    }
}
