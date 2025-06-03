//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum SliderType: String, CaseIterable, Displayable, Defaults.Serializable {

    case thumb
    case capsule

    var displayTitle: String {
        switch self {
        case .thumb:
            return L10n.thumbSlider
        case .capsule:
            return L10n.capsule
        }
    }
}
