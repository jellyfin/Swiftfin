//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

enum PosterType: String, CaseIterable, Defaults.Serializable {
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
    var localizedName: String {
        switch self {
        case .portrait:
            return "Portrait"
        case .landscape:
            return "Landscape"
        }
    }

    enum Width {
        #if os(tvOS)
        static let portrait = 250.0

        static let landscape = 490.0
        #else
        @ScaledMetric(relativeTo: .largeTitle)
        static var portrait = 100.0

        @ScaledMetric(relativeTo: .largeTitle)
        static var landscape = 200.0
        #endif
    }
}
