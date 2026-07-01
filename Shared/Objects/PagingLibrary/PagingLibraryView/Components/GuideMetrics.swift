//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

struct GuideMetrics {

    let channelColumnWidth: CGFloat
    let rowHeight: CGFloat
    let pointsPerMinute: CGFloat
    let rulerHeight: CGFloat

    static var current: GuideMetrics {
        #if os(tvOS)
        GuideMetrics(
            channelColumnWidth: 130,
            rowHeight: 120,
            pointsPerMinute: 10,
            rulerHeight: 44
        )
        #else
        GuideMetrics(
            channelColumnWidth: UIDevice.isPad ? 110 : 84,
            rowHeight: 74,
            pointsPerMinute: UIDevice.isPad ? 7 : 5,
            rulerHeight: 28
        )
        #endif
    }
}
