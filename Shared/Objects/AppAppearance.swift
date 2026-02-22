//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Displayable, Storable {

    case system
    case dark
    case light

    var displayTitle: String {
        switch self {
        case .system:
            L10n.system
        case .dark:
            L10n.dark
        case .light:
            L10n.light
        }
    }

    var style: UIUserInterfaceStyle {
        switch self {
        case .system:
            .unspecified
        case .dark:
            .dark
        case .light:
            .light
        }
    }
}
