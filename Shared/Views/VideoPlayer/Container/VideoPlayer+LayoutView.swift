//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

extension VideoPlayer {

    final class LayoutView: UIView {

        private var divisionFrames: [CGRect] = [] {
            didSet {
                if divisionFrames != oldValue {
                    setNeedsLayout()
                }
            }
        }

        var tabletopRegion: CGRect? {
            divisionFrames
                .map { bounds.intersection($0) }
                .first {
                    !$0.isEmpty && $0.width > $0.height &&
                        $0.minX == bounds.minX && $0.maxX == bounds.maxX &&
                        $0.minY > bounds.minY && $0.maxY < bounds.maxY
                }
        }

        override func updateConstraints() {
            #if os(iOS)
            if #available(iOS 27.1, *) {
                divisionFrames = reservedRegions(kind: .division).map(\.frame)
            }
            #endif

            super.updateConstraints()
        }
    }
}
