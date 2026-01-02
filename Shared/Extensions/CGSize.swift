//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

extension CGSize {

    static func Square(length: CGFloat) -> CGSize {
        CGSize(width: length, height: length)
    }

    var aspectRatio: CGFloat {
        width / height
    }

    var isLandscape: Bool {
        width >= height
    }

    var isPortrait: Bool {
        height >= width
    }
}
