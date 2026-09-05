//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PosterConfiguration: Hashable, Storable, WithDefaultValue {

    var indicators: PosterIndicator
    var showLabels: Bool
    var unplayedStyle: UnplayedIndicatorType
    var useSeriesLandscapeBackdrop: Bool

    static let `default`: PosterConfiguration = .init(
        indicators: .all,
        showLabels: true,
        unplayedStyle: .indicator,
        useSeriesLandscapeBackdrop: true
    )
}
