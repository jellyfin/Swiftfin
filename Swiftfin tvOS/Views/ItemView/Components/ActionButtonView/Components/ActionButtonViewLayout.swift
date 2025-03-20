//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// ActionButtonLayout provides a layout that distributes buttons evenly in a single row,
// with all items having equal width
struct ActionButtonViewLayout: Layout {

    // MARK: - Item Spacing

    let horizontalSpacing: CGFloat = 16

    // MARK: - Item Sizing

    let itemHeight: CGFloat = 100

    // MARK: - Layout Protocol Methods

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let width = proposal.width ?? 0
        return CGSize(width: width, height: itemHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }

        // All items go in a single row
        let indices = Array(subviews.indices)
        let itemCount = indices.count

        // Calculate spacing width between items
        let totalSpacingWidth = horizontalSpacing * CGFloat(max(0, itemCount - 1))

        // Available width for all items
        let availableWidth = bounds.width - totalSpacingWidth

        // Distribute width evenly among all items
        let itemWidth = availableWidth / CGFloat(itemCount)

        // Track horizontal position for placement
        var x = bounds.minX

        // Place each view
        for index in indices {
            subviews[index].place(
                at: CGPoint(x: x, y: bounds.minY),
                proposal: ProposedViewSize(width: itemWidth, height: itemHeight)
            )

            x += itemWidth + horizontalSpacing
        }
    }
}
