//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import Get

public extension Request {
    /// Size of the request HTTP method in bytes
    var methodSize: Int {
        method.rawValue.count
    }

    /// Size of the request URL in bytes
    var urlSize: Int {
        url?.absoluteString.count ?? 0
    }

    /// Size of the request query parameters in bytes
    var querySize: Int {
        guard let query = query else { return 0 }
        return query.reduce(0) { $0 + $1.0.count + ($1.1?.count ?? 0) + 2 }
    }

    /// Size of the request headers in bytes
    var headersSize: Int {
        guard let headers = headers else { return 0 }
        return headers.reduce(0) { $0 + $1.key.count + $1.value.count + 4 }
    }

    /// Size of the request body in bytes
    var bodySize: Int {
        var size = 0
        if let body = body {
            do {
                let bodyData = try JSONEncoder().encode(AnyEncodable(body))
                size += bodyData.count
            } catch {
                size += 0
            }
        }
        return size
    }

    /// Total size of the total request in bytes
    var requestSize: Int {
        methodSize + urlSize + querySize + headersSize + bodySize
    }
}

/// A type-erased `Encodable` to encode any value conforming to `Encodable`
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
