//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import OrderedCollections

@MainActor
final class HashCache<T: Hashable> {

    private var hashes: OrderedDictionary<String, Int> = [:]

    /// - Returns: `true` if `value` for `key` was previously inserted and updated, `false` otherwise
    @discardableResult
    func touch(key: String, value: T) -> Bool {
        let newHash = value.hashValue

        guard let existingHash = hashes[key] else {
            store(key: key, value: value)
            return false
        }

        guard existingHash != newHash else {
            hashes.removeValue(forKey: key)
            hashes[key] = existingHash
            return false
        }

        store(key: key, value: value)
        return true
    }

    private func store(key: String, value: T) {
        if hashes[key] != nil {
            hashes.removeValue(forKey: key)
        }
        hashes[key] = value.hashValue

        let d = hashes.count - 2000

        if d > 0 {
            hashes.removeFirst(d)
        }
    }
}
