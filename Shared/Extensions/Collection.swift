//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

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

    func keyed<Key>(using: KeyPath<Element, Key>) -> [Key: Element] {
        Dictionary(uniqueKeysWithValues: map { ($0[keyPath: using], $0) })
    }
}
