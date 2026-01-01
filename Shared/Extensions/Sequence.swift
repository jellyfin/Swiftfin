//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Sequence {

    func coalesced<Value>(property keyPath: WritableKeyPath<Element, Value?>, with value: Value) -> [Element] {
        map { element in
            var element = element
            element[keyPath: keyPath] = element[keyPath: keyPath] ?? value
            return element
        }
    }

    func compacted<Value>(using keyPath: KeyPath<Element, Value?>) -> [Element] {
        filter { $0[keyPath: keyPath] != nil }
    }

    func filtering(where isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
        try filter { try !isIncluded($0) }
    }

    func first<V: Equatable>(property: (Element) -> V, equalTo value: V) -> Element? {
        first { property($0) == value }
    }

    func intersecting<Value: Equatable>(_ other: some Sequence<Value>, using keyPath: KeyPath<Element, Value>) -> [Element] {
        filter { other.contains($0[keyPath: keyPath]) }
    }

    /// Returns the elements of the sequence, sorted by comparing values
    /// at the given `KeyPath` of `Element`.
    func sorted<Key: Comparable>(using keyPath: KeyPath<Element, Key>) -> [Element] {
        sorted(by: { $0[keyPath: keyPath] < $1[keyPath: keyPath] })
    }

    // TODO: a flipped version of `sorted`

    /// Returns the elements of the sequence, sorted by comparing values
    /// at the given `KeyPath` of `Element`.
    ///
    /// `nil` values are considered the maximum.
    func sorted<Key: Comparable>(using keyPath: KeyPath<Element, Key?>) -> [Element] {
        sorted {
            let x = $0[keyPath: keyPath]
            let y = $1[keyPath: keyPath]

            if let x, let y {
                return x < y
            } else if let _ = x {
                return true
            } else if let _ = y {
                return false
            }

            return true
        }
    }

    func subtracting<Value: Equatable>(_ other: some Sequence<Value>, using keyPath: KeyPath<Element, Value>) -> [Element] {
        filter { !other.contains($0[keyPath: keyPath]) }
    }

    func zipped<Value>(map mapToOther: (Element) throws -> Value) rethrows -> [(Element, Value)] {
        try map { try ($0, mapToOther($0)) }
    }
}

extension Sequence where Element: Equatable {

    func first(equalTo other: Element) -> Element? {
        first { $0 == other }
    }

    /// Returns an array containing the elements of the sequence that
    /// are also within the given sequence.
    func intersection(_ other: some Sequence<Element>) -> [Element] {
        filter { other.contains($0) }
    }

    func subtracting(_ other: some Sequence<Element>) -> [Element] {
        filter { !other.contains($0) }
    }
}

extension Sequence where Element: Collection {

    func flattened() -> [Element.Element] {
        flatMap(\.self)
    }
}
