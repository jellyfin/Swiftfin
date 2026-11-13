//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum LiveTVQuickLink: String, CaseIterable, Displayable, Identifiable, SystemImageable {

    case channels
    case recordings

    var id: String {
        rawValue
    }

    var displayTitle: String {
        switch self {
        case .channels:
            L10n.channels
        case .recordings:
            L10n.recordings
        }
    }

    var systemImage: String {
        switch self {
        case .channels:
            "play.square.stack"
        case .recordings:
            "record.circle"
        }
    }
}
