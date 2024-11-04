//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

enum SeriesDisplayOrder: String, CaseIterable, Identifiable {
    case aired = "Aired"
    case originalAirDate
    case absolute
    case dvd
    case digital
    case storyArc
    case production
    case tv
    case alternate
    case regional
    case alternateDVD = "altdvd"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .aired: return "Aired"
        case .originalAirDate: return "Original Air Date"
        case .absolute: return "Absolute"
        case .dvd: return "DVD"
        case .digital: return "Digital"
        case .storyArc: return "Story Arc"
        case .production: return "Production"
        case .tv: return "TV"
        case .alternate: return "Alternate"
        case .regional: return "Regional"
        case .alternateDVD: return "Alternate DVD"
        }
    }
}
