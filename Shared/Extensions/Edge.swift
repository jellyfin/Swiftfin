//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension Edge.Set {

    var asUIRectEdge: UIRectEdge {
        switch self {
        case .top:
            .top
        case .leading:
            .left
        case .bottom:
            .bottom
        case .trailing:
            .right
        case .all:
            .all
        case .horizontal:
            [.left, .right]
        case .vertical:
            [.top, .bottom]
        default:
            .all
        }
    }
}
