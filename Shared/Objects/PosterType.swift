//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

enum PosterType: String, CaseIterable, Displayable, Defaults.Serializable {

    case portrait
    case landscape

    var width: CGFloat {
        switch self {
        case .portrait:
            return Width.portrait
        case .landscape:
            return Width.landscape
        }
    }

    // TODO: localize
    var displayTitle: String {
        switch self {
        case .portrait:
            return "Portrait"
        case .landscape:
            return "Landscape"
        }
    }

    // TODO: Make property of the enum type, not a nested type
    enum Width {
        #if os(tvOS)
        static let portrait = 200.0

        static let landscape = 350.0
        #else
        static var portrait = 100.0

        static var landscape = 200.0
        #endif
    }
}
