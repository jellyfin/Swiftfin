//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Set {

    mutating func toggle(value: Element) {
        if contains(value) {
            remove(value)
        } else {
            insert(value)
        }
    }

    mutating func insert(contentsOf elements: [Element]) {
        for element in elements {
            insert(element)
        }
    }
}
