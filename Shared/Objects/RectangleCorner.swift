//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@OptionSet<Int>
struct RectangleCorner {

    private enum Options: Int {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }

    static var all: Self {
        [.topLeft, .topRight, .bottomLeft, .bottomRight]
    }
}
