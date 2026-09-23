//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

struct EPGLayout: Equatable {

    let channelColumnWidth: CGFloat
    let rowHeight: CGFloat
    let rulerHeight: CGFloat
    let pointsPerMinute: CGFloat

    init(
        viewLayout: ViewLayout,
        channelColumnWidth: CGFloat? = nil,
        rowHeight: CGFloat? = nil,
        rulerHeight: CGFloat? = nil,
        pointsPerMinute: CGFloat? = nil
    ) {
        let minimumRowHeight: CGFloat = viewLayout.value(standard: 74, large: 120)
        let minimumRulerHeight: CGFloat = viewLayout.value(standard: 28, large: 44)
        let traits = UITraitCollection(preferredContentSizeCategory: viewLayout.contentSizeCategory)
        let preferredProgramHeight =
            UIFont.preferredFont(forTextStyle: .footnote, compatibleWith: traits).lineHeight +
            UIFont.preferredFont(forTextStyle: .caption2, compatibleWith: traits).lineHeight +
            18
        let preferredRulerHeight = UIFont.preferredFont(forTextStyle: .caption2, compatibleWith: traits).lineHeight + 12

        self.channelColumnWidth = channelColumnWidth ?? viewLayout.value(
            standard: viewLayout.value(compact: 84, regular: 110),
            large: 130
        )
        self.rowHeight = rowHeight ?? max(minimumRowHeight, preferredProgramHeight.rounded(.up))
        self.rulerHeight = rulerHeight ?? max(minimumRulerHeight, preferredRulerHeight.rounded(.up))
        self.pointsPerMinute = pointsPerMinute ?? viewLayout.value(standard: viewLayout.value(compact: 5, regular: 7), large: 10)
    }

    /// The horizontal distance that a span of time occupies.
    func width(from start: Date, to end: Date) -> CGFloat {
        max(0, CGFloat(start.distance(to: end) / 60) * pointsPerMinute)
    }
}
