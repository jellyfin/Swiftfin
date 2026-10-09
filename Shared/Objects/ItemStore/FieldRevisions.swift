//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Tracks field revisions so older partial responses cannot overwrite newer values
struct FieldRevisions {

    private var fields: [String: UInt64] = [:]
    // A replacement blocks older responses even for fields it omitted
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
        // Full replacements also clear fields omitted by the response
        let candidates = replacing ? presentFields.union(current.keys) : presentFields

        for field in candidates where revision >= fields[field, default: 0] {
            // A missing encoded value clears the selected field
            result[field] = incoming[field]
            fields[field] = revision
        }

        if replacing {
            replacement = revision
        }

        return result
    }
}
