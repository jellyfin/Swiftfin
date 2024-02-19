//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Sequence {

    func compacted<Value>(using keyPath: KeyPath<Element, Value?>) -> [Element] {
        filter { $0[keyPath: keyPath] != nil }
    }

    /// Returns an array containing the elements of the sequence whose
    /// value at the given `KeyPath` are also within the given sequence.
    func filtered<Value: Equatable>(using keyPath: KeyPath<Element, Value>, by values: some Sequence<Value>) -> [Element] {
        filter { values.contains($0[keyPath: keyPath]) }
    }

    /// Returns the elements of the sequence, sorted by comparing values
    /// at the given `KeyPath` of `Element`.
    func sorted<Key: Comparable>(using keyPath: KeyPath<Element, Key>) -> [Element] {
        sorted(by: { $0[keyPath: keyPath] < $1[keyPath: keyPath] })
    }
}

extension Sequence where Element: Equatable {

    /// Returns an array containing the elements of the sequence that
    /// are also within the given sequence.
    func filtered(by elements: some Sequence<Element>) -> [Element] {
        filter { elements.contains($0) }
    }
}
