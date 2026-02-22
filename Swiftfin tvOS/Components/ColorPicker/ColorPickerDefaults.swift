//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum ColorPickerDefaults: CaseIterable, Displayable {

    case jellyfin
    case red
    case orange
    case yellow
    case green
    case blue

    var color: Color {
        switch self {
        case .jellyfin:
            .jellyfinPurple
        case .red:
            .red
        case .orange:
            .orange
        case .yellow:
            .yellow
        case .green:
            .green
        case .blue:
            .blue
        }
    }

    var displayTitle: String {
        switch self {
        case .jellyfin:
            "Jellyfin"
        case .red:
            L10n.red
        case .orange:
            L10n.orange
        case .yellow:
            L10n.yellow
        case .green:
            L10n.green
        case .blue:
            L10n.blue
        }
    }
}
