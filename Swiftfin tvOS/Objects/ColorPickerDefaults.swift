//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum ColorPickerDefaults: String, CaseIterable {
    case jellyfin
    case red
    case orange
    case yellow
    case green
    case blue
}

extension ColorPickerDefaults {
    var color: Color {
        switch self {
        case .jellyfin:
            return .jellyfinPurple
        case .red:
            return .red
        case .orange:
            return .orange
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .blue:
            return .blue
        }
    }
}

extension ColorPickerDefaults: Displayable {
    var displayTitle: String {
        switch self {
        case .jellyfin:
            return L10n.jellyfin
        case .red:
            return L10n.red
        case .orange:
            return L10n.orange
        case .yellow:
            return L10n.yellow
        case .green:
            return L10n.green
        case .blue:
            return L10n.blue
        }
    }
}
