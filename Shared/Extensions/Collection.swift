//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Collection {

    var asArray: [Element] {
        Array(self)
    }

    func compacted<Value>(using keyPath: KeyPath<Element, Value?>) -> [Element] {
        filter { $0[keyPath: keyPath] != nil }
    }

    func sorted<Value: Comparable>(using keyPath: KeyPath<Element, Value>) -> [Element] {
        sorted(by: { $0[keyPath: keyPath] < $1[keyPath: keyPath] })
    }

    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Collection where Element: Equatable {

    /// Filter a collection of items by containment in the given elements
    func filter(by elements: [Element]) -> [Element] {
        filter { elements.contains($0) }
    }

    /// Filter a collection of items with a `KeyPath` by containment in the given elements
    func filter<Value: Equatable>(using keyPath: KeyPath<Element, Value>, by values: [Value]) -> [Element] {
        filter { values.contains($0[keyPath: keyPath]) }
    }
}
