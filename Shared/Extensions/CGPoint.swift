//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import UIKit

extension CGPoint {

    func isNear(_ other: CGPoint, epsilon: CGFloat) -> Bool {
        let xRange = (x - epsilon) ... (x + epsilon)
        let yRange = (y - epsilon) ... (y + epsilon)

        return xRange.contains(other.x) && yRange.contains(other.y)
    }
}
