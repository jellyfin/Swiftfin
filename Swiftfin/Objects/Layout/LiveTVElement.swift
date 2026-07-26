//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum LiveTVElement: Codable, Hashable, Displayable, SystemImageable {

    case quickLinks
    case onNow
    case recordings
    case programCategory(ProgramSection)

    var displayTitle: String {
        switch self {
        case .quickLinks:
            L10n.liveTV
        case .onNow:
            L10n.onNow
        case .recordings:
            L10n.recordings
        case let .programCategory(section):
            section.displayTitle
        }
    }

    var systemImage: String {
        switch self {
        case .quickLinks:
            "rectangle.grid.2x2.fill"
        case .onNow:
            "play.tv.fill"
        case .recordings:
            "record.circle"
        case .programCategory:
            "tv"
        }
    }
}
