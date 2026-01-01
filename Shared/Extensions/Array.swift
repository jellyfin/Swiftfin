//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Array {

    func appending(_ element: Element) -> [Element] {
        self + [element]
    }

    func appending(_ element: @autoclosure () -> Element, if condition: Bool) -> [Element] {
        if condition {
            return self + [element()]
        } else {
            return self
        }
    }

    func appending(_ contents: [Element]) -> [Element] {
        self + contents
    }

    func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        try filter(predicate).count
    }

    func prepending(_ element: Element) -> [Element] {
        [element] + self
    }

    func prepending(_ element: @autoclosure () -> Element, if condition: Bool) -> [Element] {
        if condition {
            return [element()] + self
        } else {
            return self
        }
    }

    // There are instances where `removeFirst()` is called on an empty
    // collection even with a count check and causes a crash
    @discardableResult
    mutating func removeFirstSafe() -> Element? {
        guard count > 0 else { return nil }
        return removeFirst()
    }

    func removing(_ element: Element) -> [Element] where Element: Equatable {
        filter { $0 != element }
    }
}

extension Array where Element: Equatable {

    mutating func removeFirst(equalTo element: Element) {
        if let index = firstIndex(of: element) {
            remove(at: index)
        }
    }

    mutating func removeAll(equalTo element: Element) {
        removeAll { $0 == element }
    }
}
