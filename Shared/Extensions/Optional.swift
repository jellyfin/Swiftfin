//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Optional where Wrapped: Collection {

    mutating func appendedOrInit(_ element: Wrapped.Element) -> [Wrapped.Element] {
        if let self {
            return self + [element]
        } else {
            return [element]
        }
    }
}
