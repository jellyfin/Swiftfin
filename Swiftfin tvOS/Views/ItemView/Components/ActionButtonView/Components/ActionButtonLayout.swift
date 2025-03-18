//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Rewrite this or something to make sense to humans
// TODO: Remove all the AI comments
// TODO: Verify this does everything we need/want it to do
struct ActionButtonLayout: Layout {

    // MARK: - Static Item Spacing

    let horizontalSpacing: CGFloat = 25
    let verticalSpacing: CGFloat = 20

    // MARK: - Static Item Sizing

    let minItemWidth: CGFloat = 100
    let itemHeight: CGFloat = 100

    // MARK: - Track Row Sizing

    @State
    var maxItemsPerRow: Int?
    @State
    var menuItemIndex: Int?

    // MARK: - Actions

    var onRowsComputed: (([[Int]]) -> Void)?

    // MARK: - Layout Protocol Methods

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let rows = computeRowsWithMenuConstraint(proposal: proposal, subviews: subviews)

        onRowsComputed?(rows)

        var height: CGFloat = 0
        for (index, _) in rows.enumerated() {
            height += itemHeight

            if index < rows.count - 1 {
                height += verticalSpacing
            }
        }
        let width = proposal.width ?? 0

        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }

        // Use our enhanced row computation that considers menu position
        let rows = computeRowsWithMenuConstraint(proposal: proposal, subviews: subviews)

        // Track vertical position
        var y = bounds.minY

        // Place views in each row
        for row in rows {
            // Total spacing width between items
            let totalSpacingWidth = horizontalSpacing * CGFloat(max(0, row.count - 1))

            // Available width for all items in this row
            let availableWidth = bounds.width - totalSpacingWidth

            // Calculate individual item widths based on their proportions
            var itemWidths = [CGFloat]()

            // If menu is in this row, give it less space
            let hasMenu = menuItemIndex.map { row.contains($0) } ?? false

            if hasMenu && row.count > 1 {
                // Find menu position in this row
                let menuIndexInRow = menuItemIndex.flatMap { menuIndex in
                    row.firstIndex(of: menuIndex)
                } ?? 0

                // Distribute width - other items get equal shares, menu gets less
                let menuWidthRatio: CGFloat = 0.6 // Menu takes 60% of what others take
                let totalParts = CGFloat(row.count - 1) + menuWidthRatio
                let regularItemWidth = availableWidth / totalParts

                // Assign widths to each item
                for (i, _) in row.enumerated() {
                    if i == menuIndexInRow {
                        itemWidths.append(regularItemWidth * menuWidthRatio)
                    } else {
                        itemWidths.append(regularItemWidth)
                    }
                }
            } else {
                // Equal distribution when no menu or menu is alone
                let equalWidth = availableWidth / CGFloat(row.count)
                itemWidths = Array(repeating: equalWidth, count: row.count)
            }

            // Track horizontal position for placement
            var x = bounds.minX

            // Place each view
            for (i, index) in row.enumerated() {
                let width = max(minItemWidth, itemWidths[i])

                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: width, height: itemHeight)
                )

                x += width + horizontalSpacing
            }

            // Move to the next row
            y += itemHeight + verticalSpacing
        }
    }

    // MARK: - Helper Methods

    /// Enhanced row computation that ensures menu appears in first 4 positions
    private func computeRowsWithMenuConstraint(proposal: ProposedViewSize, subviews: Subviews) -> [[Int]] {
        guard !subviews.isEmpty else { return [] }

        // Initialize rows
        var rows: [[Int]] = [[]]
        var currentRow = 0
        var remainingWidth = proposal.width ?? .infinity

        // Handle cases where menu should be constrained
        guard let menuIndex = menuItemIndex, menuIndex >= 0, menuIndex < subviews.count else {
            // No menu constraint - use standard row computation
            return computeRows(proposal: proposal, subviews: subviews)
        }

        // Track how many items we've placed
        var itemsPlaced = 0

        // First, handle items before the menu
        for index in subviews.indices {
            // Skip menu for now, we'll place it specifically
            if index == menuIndex {
                continue
            }

            // Once we've placed 3 items, we need to consider menu placement
            if itemsPlaced >= 3 && !rows[currentRow].contains(menuIndex) {
                // Check if menu can fit in current row
                let menuWidth = max(minItemWidth, subviews[menuIndex].sizeThatFits(.unspecified).width)

                if remainingWidth >= menuWidth + horizontalSpacing {
                    // Add menu to current row
                    rows[currentRow].append(menuIndex)
                    remainingWidth -= menuWidth + horizontalSpacing
                } else {
                    // Start new row with menu
                    currentRow += 1
                    rows.append([menuIndex])
                    remainingWidth = (proposal.width ?? .infinity) - menuWidth
                }

                // After placing 3 items + menu, any further items go to next rows
                if index < menuIndex || itemsPlaced > 3 {
                    // Check if new row needed for this item
                    let viewWidth = max(minItemWidth, subviews[index].sizeThatFits(.unspecified).width)

                    if remainingWidth < viewWidth + horizontalSpacing {
                        currentRow += 1
                        rows.append([])
                        remainingWidth = proposal.width ?? .infinity
                    }

                    // Add this item
                    rows[currentRow].append(index)
                    remainingWidth -= viewWidth + horizontalSpacing
                }

                continue
            }

            // Standard row calculation for items before menu constraint applies
            let viewWidth = max(minItemWidth, subviews[index].sizeThatFits(.unspecified).width)

            // Check if we need a new row
            let needsNewRow = rows[currentRow].isEmpty ? false : remainingWidth < (viewWidth + horizontalSpacing)
            let reachedMaxItemsInRow = maxItemsPerRow.map { rows[currentRow].count >= $0 } ?? false

            if needsNewRow || reachedMaxItemsInRow {
                currentRow += 1
                rows.append([])
                remainingWidth = proposal.width ?? .infinity
            }

            // Add item to current row
            rows[currentRow].append(index)
            remainingWidth -= viewWidth + horizontalSpacing
            itemsPlaced += 1
        }

        // If menu hasn't been placed yet, place it now
        if !rows.joined().contains(menuIndex) {
            // Try to place it in the first row if possible
            if rows[0].count < 4 {

                if rows[0].isEmpty {
                    rows[0].append(menuIndex)
                } else {
                    rows[0].append(menuIndex)
                }
            } else {
                // Add menu to a new row
                rows.append([menuIndex])
            }
        }

        return rows
    }

    /// Original row computation (used as fallback when no menu constraints)
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Int]] {
        var rows: [[Int]] = [[]]
        var currentRow = 0
        var remainingWidth = proposal.width ?? .infinity

        // Determine how many items can fit in each row
        for index in subviews.indices {
            let viewWidth = max(minItemWidth, subviews[index].sizeThatFits(.unspecified).width)

            // Check if we need to move to a new row
            let needsNewRow = rows[currentRow].isEmpty ? false : remainingWidth < (viewWidth + horizontalSpacing)

            // If we're using maxItemsPerRow, also check that constraint
            let reachedMaxItemsInRow = maxItemsPerRow.map { rows[currentRow].count >= $0 } ?? false

            if needsNewRow || reachedMaxItemsInRow {
                // Start a new row
                currentRow += 1
                rows.append([])
                remainingWidth = proposal.width ?? .infinity
            }

            // Add the view to the current row
            rows[currentRow].append(index)

            // Subtract used width plus spacing
            remainingWidth -= viewWidth

            // Only subtract spacing if this isn't the last item
            if index < subviews.endIndex - 1 {
                remainingWidth -= horizontalSpacing
            }
        }

        return rows
    }
}
