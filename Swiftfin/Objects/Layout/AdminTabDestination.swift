//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum AdminTabDestination: String, CaseIterable, Codable, Hashable, Identifiable, Displayable, SystemImageable {

    case dashboard
    case activity
    case sessions

    var id: String {
        rawValue
    }

    var displayTitle: String {
        switch self {
        case .dashboard:
            L10n.dashboard
        case .activity:
            L10n.activity
        case .sessions:
            L10n.sessions
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            "server.rack"
        case .activity:
            "list.bullet.rectangle"
        case .sessions:
            "person.2.fill"
        }
    }
}
