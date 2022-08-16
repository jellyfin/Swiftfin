//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum PosterType: String, CaseIterable, Defaults.Serializable {
    case portrait
    case landscape

    var localizedName: String {
        switch self {
        case .portrait:
            return "Portrait"
        case .landscape:
            return "Landscape"
        }
    }
}
