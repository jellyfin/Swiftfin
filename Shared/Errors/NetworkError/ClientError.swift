//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation

struct ClientError: NetworkError {

    @Router
    private var router

    let statusCode: Int?

    init(statusCode: Int) {
        self.statusCode = statusCode
    }

    var displayTitle: String {
        L10n.clientError
    }

    var errorDescription: String? {
        switch statusCode {
        case 400:
            return L10n.badRequest
        case 401:
            return L10n.unauthorized
        case 403:
            return L10n.forbidden
        case 404:
            return L10n.notFound
        case 409:
            return L10n.conflict
        case 413:
            return L10n.payloadTooLarge
        default:
            if let statusCode {
                return L10n.unknownNetworkError(statusCode)
            } else {
                return L10n.unknownError
            }
        }
    }

    var recoverySuggestion: String? {
        switch statusCode {
        case 401:
            return L10n.refreshAccountToken
        case 403:
            return L10n.contactAdminForAccess
        case 404:
            return L10n.resourceDeletedOrMoved
        case 409:
            return L10n.conflictWithResourceState
        case 413:
            return L10n.fileTooLarge
        default:
            return nil
        }
    }

    var systemImage: String {
        #if os(iOS)
        return "ipad.landscape.and.iphone.slash"
        #elseif os(tvOS)
        return "tv.slash"
        #else
        return "macbook.slash"
        #endif
    }

    var isRetryable: Bool {
        false
    }

    var retryAfter: TimeInterval? {
        nil
    }
}
