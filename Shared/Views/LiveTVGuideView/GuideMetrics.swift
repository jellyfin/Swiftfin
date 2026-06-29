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
    let headerHeight: CGFloat
    let pointsPerMinute: CGFloat
    let interval: Int
    let surface: Color

    static var current: GuideMetrics {
        #if os(tvOS)
        GuideMetrics(
            channelColumnWidth: 140,
            rowHeight: 140,
            headerHeight: 60,
            pointsPerMinute: 14,
            interval: 30,
            surface: .black
        )
        #else
        GuideMetrics(
            channelColumnWidth: 76,
            rowHeight: 76,
            headerHeight: 34,
            pointsPerMinute: UIDevice.isPad ? 7 : 5,
            interval: 30,
            surface: .systemBackground
        )
        #endif
    }
}

struct GuideScrollOffsetKey: PreferenceKey {

    static let space = "guideScroll"

    static let defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}
