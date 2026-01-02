//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

struct Direction: OptionSet {

    let rawValue: Int

    static let up = Direction(rawValue: 1 << 0)
    static let down = Direction(rawValue: 1 << 1)
    static let left = Direction(rawValue: 1 << 2)
    static let right = Direction(rawValue: 1 << 3)

    static let vertical: Direction = [.up, .down]
    static let horizontal: Direction = [.left, .right]
    static let all: Direction = [.up, .down, .left, .right]

    static let allButDown: Direction = [.up, .left, .right]

    var isHorizontal: Bool {
        contains(.left) || contains(.right)
    }

    var isVertical: Bool {
        contains(.up) || contains(.down)
    }
}
