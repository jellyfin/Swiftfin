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

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .aired:
            return L10n.aired
        case .originalAirDate:
            return L10n.originalAirDate
        case .absolute:
            return L10n.absolute
        case .dvd:
            return L10n.dvd
        case .digital:
            return L10n.digital
        case .storyArc:
            return L10n.storyArc
        case .production:
            return L10n.production
        case .tv:
            return L10n.tv
        case .alternate:
            return L10n.alternate
        case .regional:
            return L10n.regional
        case .alternateDVD:
            return L10n.alternateDVD
        }
    }
}
