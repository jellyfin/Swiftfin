//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

struct Direction: OptionSet {

    let rawValue: Int

    static let up = Self(rawValue: 1 << 0)
    static let down = Self(rawValue: 1 << 1)
    static let left = Self(rawValue: 1 << 2)
    static let right = Self(rawValue: 1 << 3)

    static var vertical: Self {
        [.up, .down]
    }

    static var horizontal: Self {
        [.left, .right]
    }

    static var all: Self {
        [.up, .down, .left, .right]
    }

    static var allButDown: Self {
        [.up, .left, .right]
    }

    var isHorizontal: Bool {
        contains(.left) || contains(.right)
    }

    var isVertical: Bool {
        contains(.up) || contains(.down)
    }
}
