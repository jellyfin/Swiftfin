//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

// TODO: remove and just use primitive values instead?

enum PlaybackRate: Storable {

    case half
    case one
    case oneQuarter
    case oneHalf
    case two
    case custom(rate: Double)
    
    var rate: Double {
        switch self {
        case .half: 0.5
        case .one: 1.0
        case .oneQuarter: 1.25
        case .oneHalf: 1.5
        case .two: 2.0
        case .custom(let rate): rate
        }
    }
}
