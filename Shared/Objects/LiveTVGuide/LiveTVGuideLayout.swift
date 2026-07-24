//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

struct LiveTVGuideLayout: Equatable {

    let channelColumnWidth: CGFloat
    let rowHeight: CGFloat
    let rulerHeight: CGFloat
    let pointsPerMinute: CGFloat

    init(
        channelColumnWidth: CGFloat = UIDevice.isTV ? 130 : UIDevice.isPad ? 110 : 84,
        rowHeight: CGFloat = UIDevice.isTV ? 120 : 74,
        rulerHeight: CGFloat = UIDevice.isTV ? 44 : 28,
        pointsPerMinute: CGFloat = UIDevice.isTV ? 10 : UIDevice.isPad ? 7 : 5
    ) {
        self.channelColumnWidth = channelColumnWidth
        self.rowHeight = rowHeight
        self.rulerHeight = rulerHeight
        self.pointsPerMinute = pointsPerMinute
    }

    /// The horizontal distance that a span of time occupies.
    func width(from start: Date, to end: Date) -> CGFloat {
        max(0, CGFloat(start.distance(to: end) / 60) * pointsPerMinute)
    }
}
