//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation

enum DarkAppIcon: String, AppIcon {
    
    case blue
    case green
    case orange
    case red
    case yellow
    case jellyfin
    
    var displayTitle: String {
        switch self {
        case .blue:
            return "Blue"
        case .green:
            return "Green"
        case .orange:
            return "Orange"
        case .red:
            return "Red"
        case .yellow:
            return "Yellow"
        case .jellyfin:
            return "Jellyfin"
        }
    }
    
    static let tag: String = "dark"
}
