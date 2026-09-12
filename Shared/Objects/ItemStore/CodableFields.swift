//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Use the SDK's Codable implementation as the field schema. Both sides use the
/// same codec, so dates and nested values don't depend on the server's JSON format.
enum CodableFields {
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

/// Tracks fields as they arrive. A replacement also protects fields that have
/// never been loaded, preventing an older response from filling an intentional nil.
struct FieldRevisions {
    private var fields: [String: UInt64] = [:]
    private var replacement: UInt64 = 0

    var latest: UInt64 {
        max(replacement, fields.values.max() ?? 0)
    }

    func accepts(_ revision: UInt64) -> Bool {
        revision >= replacement
    }

    mutating func clear(at revision: UInt64) {
        fields.removeAll()
        replacement = revision
    }

    mutating func merge(
        _ current: [String: Any],
        with incoming: [String: Any],
        presentFields: Set<String>,
        revision: UInt64,
        replacing: Bool = false
    ) -> [String: Any] {
        guard accepts(revision) else { return current }
        var result = current
        let candidates = replacing ? presentFields.union(current.keys) : presentFields
        for field in candidates where revision >= fields[field, default: 0] {
            // A key present on the wire but absent from the encoded DTO is an explicit null.
            result[field] = incoming[field]
            fields[field] = revision
        }
        if replacing {
            replacement = revision
        }
        return result
    }
}
