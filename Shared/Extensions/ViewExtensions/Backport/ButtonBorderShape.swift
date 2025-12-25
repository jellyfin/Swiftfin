//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum ButtonBorderShape {
    case automatic
    case capsule
    case roundedRectangle
    case circle

    var swiftUIValue: SwiftUI.ButtonBorderShape {
        switch self {
        case .automatic: .automatic
        case .capsule: .capsule
        case .roundedRectangle: .roundedRectangle
        case .circle:
            if #available(iOS 17, *) {
                .circle
            } else {
                .roundedRectangle
            }
        }
    }
}
