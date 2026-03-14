//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension UIGestureRecognizer {

    func unitPoint(in view: UIView) -> UnitPoint {
        let location = location(in: view)
        return .init(x: location.x / view.frame.width, y: location.y / view.frame.height)
    }
}
