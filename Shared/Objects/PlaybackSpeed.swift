//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum PlaybackSpeed: CaseIterable, Displayable, Hashable, RawRepresentable, Storable {

    typealias RawValue = Float

    case quarter
    case half
    case threeQuarter
    case one
    case oneQuarter
    case oneHalf
    case oneThreeQuarter
    case two
    case custom(Float)

    init(rawValue: Float) {
        switch rawValue {
        case 0.25:
            self = .quarter
        case 0.5:
            self = .half
        case 0.75:
            self = .threeQuarter
        case 1.0:
            self = .one
        case 1.25:
            self = .oneQuarter
        case 1.5:
            self = .oneHalf
        case 1.75:
            self = .oneThreeQuarter
        case 2.0:
            self = .two
        default:
            self = .custom(rawValue)
        }
    }

    var rawValue: Float {
        switch self {
        case .quarter:
            0.25
        case .half:
            0.5
        case .threeQuarter:
            0.75
        case .one:
            1.0
        case .oneQuarter:
            1.25
        case .oneHalf:
            1.5
        case .oneThreeQuarter:
            1.75
        case .two:
            2.0
        case let .custom(value):
            value
        }
    }

    var displayTitle: String {
        rawValue.formatted(.playbackRate(precision: 2))
    }

    static var allCases: [PlaybackSpeed] {
        [.quarter, .half, .threeQuarter, .one, .oneQuarter, .oneHalf, .oneThreeQuarter, .two]
    }
}
