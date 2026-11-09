//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Fits columns into the available content width, keeping at least one column
/// in windows narrower than the preferred minimum.
struct AdaptiveColumns {

    let minimumWidth: CGFloat
    let maximumCount: Int
    var spacing: CGFloat = 0

    func count(for width: CGFloat) -> Int {
        guard width.isFinite, width > 0 else { return 1 }

        let count = floor((width + spacing) / (minimumWidth + spacing))
        let maximumCount = max(1, maximumCount)
        // Clamp before converting: CGFloat(Int.max) rounds beyond Int's range.
        if count >= CGFloat(maximumCount) {
            return maximumCount
        }
        return Int(max(1, count))
    }

    func itemWidth(for width: CGFloat) -> CGFloat {
        guard width.isFinite, width > 0 else { return 0 }

        let count = CGFloat(count(for: width))
        return max(0, (width - spacing * (count - 1)) / count)
    }
}
