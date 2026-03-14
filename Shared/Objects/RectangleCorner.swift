//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

struct RectangleCorner: OptionSet {

    let rawValue: UInt

    static let topLeft = RectangleCorner(rawValue: 1 << 0)
    static let topRight = RectangleCorner(rawValue: 1 << 1)
    static let bottomLeft = RectangleCorner(rawValue: 1 << 2)
    static let bottomRight = RectangleCorner(rawValue: 1 << 3)

    static let allCorners: RectangleCorner = [
        .topLeft,
        .topRight,
        .bottomLeft,
        .bottomRight,
    ]
}
