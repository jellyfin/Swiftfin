//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults

enum PlaybackCompatibility: String, CaseIterable, Defaults.Serializable, Displayable {
    case auto = "Auto"
    case compatible = "Most Compatible"
    case direct = "Direct Play"
    case custom = "Custom"

    var displayTitle: String {
        rawValue
    }
}
