//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@OptionSet<Int>
struct Direction {

    private enum Options: Int {
        case up
        case down
        case left
        case right
    }

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
