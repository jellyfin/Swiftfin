//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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

    var id: String {
        rawValue
    }

    var displayTitle: String {
        switch self {
        case .aired:
            L10n.aired
        case .originalAirDate:
            L10n.originalAirDate
        case .absolute:
            L10n.absolute
        case .dvd:
            L10n.dvd
        case .digital:
            L10n.digital
        case .storyArc:
            L10n.storyArc
        case .production:
            L10n.production
        case .tv:
            L10n.tv
        case .alternate:
            L10n.alternate
        case .regional:
            L10n.regional
        case .alternateDVD:
            L10n.alternateDVD
        }
    }
}
