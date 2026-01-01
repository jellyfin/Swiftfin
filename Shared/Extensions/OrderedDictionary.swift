//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import OrderedCollections

extension OrderedDictionary {

    var isNotEmpty: Bool {
        !isEmpty
    }

    func compactKeys<WrappedKey: Hashable>() -> OrderedDictionary<WrappedKey, Value> where Key == WrappedKey? {
        reduce(into: OrderedDictionary<WrappedKey, Value>()) { result, pair in
            if let unwrappedKey = pair.key {
                result[unwrappedKey] = pair.value
            }
        }
    }

    func sortedKeys(by areInIncreasingOrder: (Key, Key) -> Bool) -> Self {
        let sortedKeys = keys.sorted(by: areInIncreasingOrder)

        return OrderedDictionary(uniqueKeysWithValues: sortedKeys.compactMap { key in
            guard let value = self[key] else { return nil }
            return (key, value)
        })
    }

    func sortedKeys<KeyValue: Comparable>(using keyValue: (Key) -> KeyValue) -> Self {
        sortedKeys { lhs, rhs in
            keyValue(lhs) < keyValue(rhs)
        }
    }
}
