//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// TODO: profile, see if performance improved with swift-yyjson

extension JSONSerialization {

    /// Encodes a value as a JSON field dictionary
    static func encode(_ value: some Encodable) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }

        return object
    }

    static func decode<Value: Decodable>(_ type: Value.Type, from object: [String: Any]) throws -> Value {
        let data = try JSONSerialization.data(withJSONObject: object)
        return try JSONDecoder().decode(type, from: data)
    }
}
