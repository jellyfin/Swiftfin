//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Algorithms
import Foundation

extension Collection {

    var asArray: [Element] {
        Array(self)
    }

    var isNotEmpty: Bool {
        !isEmpty
    }

    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    func keyed<Key>(using keyPath: KeyPath<Element, Key>) -> [Key: Element] {
        Dictionary(uniqueKeysWithValues: map { ($0[keyPath: keyPath], $0) })
    }

    /// Splits a collection sorted by ascending key into elements at or before the value and those after it.
    func split<Value: Comparable>(
        after value: Value,
        sortedBy key: (Element) -> Value
    ) -> (atOrBefore: SubSequence, after: SubSequence) {
        let boundary = partitioningIndex { key($0) > value }
        return (self[..<boundary], self[boundary...])
    }
}
