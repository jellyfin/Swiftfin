//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
            let vel = velocity(in: view)

            let isHorizontal = abs(vel.y) < abs(vel.x)
            let isVertical = abs(vel.x) < abs(vel.y)

//            print("vel: \(vel), isHorizontal: \(isHorizontal), isVertical: \(isVertical), direction: \(direction)")

            switch direction {
            case .horizontal where isHorizontal: ()
            case .vertical where isVertical: ()
            case .up where isVertical && vel.y < 0: ()
            case .down where isVertical && vel.y > 0: ()
            case .left where isHorizontal && vel.x < 0: ()
            case .right where isHorizontal && vel.x > 0: ()
            case .all: ()
            default:
                state = .cancelled
            }
        }
    }
}
