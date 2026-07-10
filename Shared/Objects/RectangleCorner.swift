//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

struct RectangleCorner: OptionSet {

    let rawValue: Int

    static let topLeft = Self(rawValue: 1 << 0)
    static let topRight = Self(rawValue: 1 << 1)
    static let bottomLeft = Self(rawValue: 1 << 2)
    static let bottomRight = Self(rawValue: 1 << 3)

    static var all: Self {
        [.topLeft, .topRight, .bottomLeft, .bottomRight]
    }
}
