//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

struct ConnectionError: NetworkError {

    enum Reason {
        case noConnection
        case connectionLost
        case dnsLookupFailed
        case timedOut
        case secureConnectionFailed
        case cancelled
        case invalidCertificate
        case unknown
    }

    let reason: Reason
    let underlyingError: URLError?

    init(_ urlError: URLError) {
        self.underlyingError = urlError
        switch urlError.code {
        case .notConnectedToInternet:
            self.reason = .noConnection
        case .networkConnectionLost:
            self.reason = .connectionLost
        case .cannotFindHost, .dnsLookupFailed:
            self.reason = .dnsLookupFailed
        case .timedOut:
            self.reason = .timedOut
        case .secureConnectionFailed:
            self.reason = .secureConnectionFailed
        case .serverCertificateHasBadDate,
             .serverCertificateUntrusted,
             .serverCertificateHasUnknownRoot,
             .serverCertificateNotYetValid:
            self.reason = .invalidCertificate
        case .cancelled:
            self.reason = .cancelled
        default:
            self.reason = .unknown
        }
    }

    var statusCode: Int? {
        nil
    }

    var displayTitle: String {
        L10n.connectionError
    }

    var errorDescription: String? {
        switch reason {
        case .noConnection:
            return L10n.noConnection
        case .connectionLost:
            return L10n.connectionLost
        case .dnsLookupFailed:
            return L10n.dnsLookupFailed
        case .timedOut:
            return L10n.timedOut
        case .secureConnectionFailed:
            return L10n.secureConnectionFailed
        case .invalidCertificate:
            return L10n.invalidCertificate
        case .cancelled:
            return L10n.cancelled
        case .unknown:
            return L10n.unknownError
        }
    }

    var recoverySuggestion: String? {
        switch reason {
        case .noConnection:
            return L10n.checkInternetConnection
        case .dnsLookupFailed:
            return L10n.verifyServerAddress
        case .timedOut:
            return L10n.checkConnectionRetry
        case .secureConnectionFailed, .invalidCertificate:
            return L10n.verifyCertificate
        default:
            return nil
        }
    }

    var systemImage: String {
        "network.slash"
    }

    var isRetryable: Bool {
        true
    }

    var retryAfter: TimeInterval? {
        nil
    }
}
