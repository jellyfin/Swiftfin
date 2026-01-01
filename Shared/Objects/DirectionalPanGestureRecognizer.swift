//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

class DirectionalPanGestureRecognizer: UIPanGestureRecognizer {

    var direction: Direction

    init(direction: Direction, target: AnyObject, action: Selector) {
        self.direction = direction
        super.init(target: target, action: action)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        if state == .began {
            let velocity = velocity(in: view)

            let isUp = velocity.y < 0
            let isHorizontal = velocity.y.magnitude < velocity.x.magnitude
            let isVertical = velocity.x.magnitude < velocity.y.magnitude

            switch direction {
            case .all: ()
            case .allButDown where isUp || isHorizontal: ()
            case .horizontal where isHorizontal: ()
            case .vertical where isVertical: ()
            case .up where isVertical && velocity.y < 0: ()
            case .down where isVertical && velocity.y > 0: ()
            case .left where isHorizontal && velocity.x < 0: ()
            case .right where isHorizontal && velocity.x > 0: ()
            default:
                state = .cancelled
            }
        }
    }
}
