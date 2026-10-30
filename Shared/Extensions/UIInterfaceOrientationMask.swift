//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit
#if os(tvOS)
import SwiftfinMacros
#endif

#if os(iOS)
extension UIInterfaceOrientationMask: @retroactive CustomDebugStringConvertible {}
#endif

extension UIInterfaceOrientationMask {

    // swiftformat:disable:next redundantPublic
    public var debugDescription: String {
        switch self {
        case .all:
            "All Orientations"
        case .allButUpsideDown:
            "All But Upside Down"
        case .portrait:
            "Portrait"
        case .portraitUpsideDown:
            "Portrait Upside Down"
        case .landscape:
            "Landscape"
        case .landscapeLeft:
            "Landscape Left"
        case .landscapeRight:
            "Landscape Right"
        default:
            "Unknown"
        }
    }
}

#if os(tvOS)
@OptionSet<Int>
struct UIInterfaceOrientationMask: CustomDebugStringConvertible {

    private enum Options: Int {

        case portrait = 1
        case landscapeLeft = 4
        case landscapeRight = 3
        case portraitUpsideDown = 2
    }

    static var landscape: Self {
        [.landscapeLeft, .landscapeRight]
    }

    static var all: Self {
        [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]
    }

    static var allButUpsideDown: Self {
        [.portrait, .landscapeLeft, .landscapeRight]
    }
}
#endif
