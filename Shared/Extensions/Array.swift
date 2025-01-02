//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Array {

    func appending(_ element: Element) -> [Element] {
        self + [element]
    }

    func appending(_ element: Element, if condition: Bool) -> [Element] {
        if condition {
            return self + [element]
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

    func prepending(_ element: Element, if condition: Bool) -> [Element] {
        if condition {
            return [element] + self
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
}

// extension Array where Element: RawRepresentable<String> {
//
//    var asCommaString: String {}
// }
