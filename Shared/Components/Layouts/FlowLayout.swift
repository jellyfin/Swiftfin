//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A custom layout that arranges views in a flow pattern, automatically wrapping items to a second row
/// when they exceed the available width. When wrapping occurs, items maintain their order with
/// configurable fill direction - either filling the bottom row first (bottomUp) or the top row first (topDown).
struct FlowLayout: Layout {

    // MARK: - Fill Direction

    /// Controls the priority order when distributing items across rows
    enum FillDirection {
        /// Fill the top row first, overflow goes to bottom row
        case topDown
        /// Fill the bottom row first, overflow goes to top row (default)
        case bottomUp
    }

    // MARK: - Properties

    /// The alignment of content within each row (leading, center, or trailing)
    var alignment: Alignment = .center

    /// The horizontal spacing between items within the same row
    var spacing: CGFloat = 8

    /// The vertical spacing between the top and bottom rows when content wraps
    var lineSpacing: CGFloat = 8

    /// Controls whether items fill from the top row down or bottom row up when wrapping.
    /// - bottomUp (default): Maximize items in bottom row, overflow to top
    /// - topDown: Maximize items in top row, overflow to bottom
    var fillDirection: FillDirection = .bottomUp

    // MARK: - Determine the Maximum Size that Fits

    /// Calculates the minimum size needed to display all subviews according to the flow layout rules.
    /// - Parameters:
    ///   - proposal: The proposed size from the parent view
    ///   - subviews: The collection of child views to layout
    ///   - cache: Storage for any computed values (unused in this implementation)
    /// - Returns: The total size needed to display all subviews
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let rows = computeRows(sizes: sizes, maxWidth: maxWidth)

        return computeTotalSize(rows: rows, sizes: sizes)
    }

    // MARK: - Place Items in Sub-Views

    /// Positions each subview within the given bounds according to the flow layout rules.
    /// Items are placed left-to-right, wrapping to a second row when necessary.
    /// - Parameters:
    ///   - bounds: The rectangle in which to place all subviews
    ///   - proposal: The proposed size from the parent view
    ///   - subviews: The collection of child views to position
    ///   - cache: Storage for any computed values (unused in this implementation)
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let rows = computeRows(sizes: sizes, maxWidth: bounds.width)

        var yOffset: CGFloat = bounds.minY

        for row in rows {
            let rowHeight = row.map { sizes[$0].height }.max() ?? 0
            let rowWidth = computeRowWidth(indices: row, sizes: sizes)
            let xOffset = computeXOffset(rowWidth: rowWidth, bounds: bounds)

            var x = xOffset
            for index in row {
                let size = sizes[index]
                let y = yOffset + (rowHeight - size.height) / 2

                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )

                x += size.width + spacing
            }

            yOffset += rowHeight + lineSpacing
        }
    }

    // MARK: - Compute Rows

    /// Determines how to distribute items across rows based on the available width.
    /// Items prefer to stay on a single row, but wrap to two rows when necessary.
    /// The fill behavior depends on fillDirection:
    /// - bottomUp: Bottom row is filled first before items move to the top row
    /// - topDown: Top row is filled first before items overflow to the bottom row
    /// - Parameters:
    ///   - sizes: Array of sizes for each subview
    ///   - maxWidth: The maximum width available for layout
    /// - Returns: Array of row arrays, where each row contains the indices of items in that row
    private func computeRows(sizes: [CGSize], maxWidth: CGFloat) -> [[Int]] {
        guard sizes.count > 1 else {
            return sizes.isEmpty ? [] : [[0]]
        }

        let allIndices = Array(0 ..< sizes.count)
        let totalWidth = computeRowWidth(indices: allIndices, sizes: sizes)

        if totalWidth <= maxWidth {
            return [allIndices]
        }

        let splitIndex = findSplitIndex(sizes: sizes, maxWidth: maxWidth)

        if splitIndex == 0 {
            return [allIndices]
        }

        return [
            Array(0 ..< splitIndex),
            Array(splitIndex ..< sizes.count),
        ]
    }

    // MARK: - Find Split Index

    /// Calculates where to split items between top and bottom rows.
    /// For bottomUp: Ensures the bottom row is as full as possible while fitting within maxWidth.
    /// For topDown: Ensures the top row is as full as possible while fitting within maxWidth.
    /// Enforces a minimum of 2 items in the smaller row to avoid lonely single items.
    /// - Parameters:
    ///   - sizes: Array of sizes for each subview
    ///   - maxWidth: The maximum width available for layout
    /// - Returns: The index at which to split (items before this index go to top row)
    private func findSplitIndex(sizes: [CGSize], maxWidth: CGFloat) -> Int {
        switch fillDirection {

        /// Fill Pattern:
        /// 1 2
        /// 3 4 5 6 7
        case .bottomUp:
            var topRowCount = 0

            for i in 0 ..< sizes.count {
                let bottomIndices = Array(i ..< sizes.count)
                let bottomWidth = computeRowWidth(indices: bottomIndices, sizes: sizes)

                if bottomWidth <= maxWidth {
                    topRowCount = i
                    break
                }
            }

            if topRowCount == 1 {
                topRowCount = 2
            }

            return topRowCount

        /// Fill Pattern:
        /// 1 2 3 4 5
        /// 6 7
        case .topDown:
            var topRowCount = sizes.count - 1

            for i in 1 ..< sizes.count {
                let topIndices = Array(0 ..< i)
                let topWidth = computeRowWidth(indices: topIndices, sizes: sizes)

                if topWidth <= maxWidth {
                    topRowCount = i
                } else {
                    break
                }
            }

            if topRowCount == sizes.count - 1 && sizes.count >= 3 {
                topRowCount = sizes.count - 2
            }

            return topRowCount
        }
    }

    // MARK: - Compute Row Width

    /// Calculates the total width needed for a row of items including spacing.
    /// - Parameters:
    ///   - indices: Array of indices representing items in the row
    ///   - sizes: Array of all item sizes
    /// - Returns: Total width including item widths and spacing between them
    private func computeRowWidth(indices: [Int], sizes: [CGSize]) -> CGFloat {
        guard !indices.isEmpty else { return 0 }

        let itemsWidth = indices.reduce(0) { $0 + sizes[$1].width }
        let spacingWidth = spacing * CGFloat(indices.count - 1)

        return itemsWidth + spacingWidth
    }

    // MARK: - Compute X Offset

    /// Calculates the starting X position for a row based on the alignment setting.
    /// - Parameters:
    ///   - rowWidth: The total width of the row
    ///   - bounds: The available bounds for layout
    /// - Returns: The X coordinate where the row should start
    private func computeXOffset(rowWidth: CGFloat, bounds: CGRect) -> CGFloat {
        switch alignment.horizontal {
        case .trailing, .listRowSeparatorTrailing:
            return bounds.maxX - rowWidth
        case .center:
            return bounds.minX + (bounds.width - rowWidth) / 2
        default:
            return bounds.minX
        }
    }

    // MARK: - Compute Total Size

    /// Calculates the total size needed to display all rows with proper spacing.
    /// - Parameters:
    ///   - rows: Array of row arrays containing item indices
    ///   - sizes: Array of all item sizes
    /// - Returns: The total size encompassing all rows
    private func computeTotalSize(rows: [[Int]], sizes: [CGSize]) -> CGSize {
        guard !rows.isEmpty else { return .zero }

        let rowHeights = rows.map { row in
            row.map { sizes[$0].height }.max() ?? 0
        }

        let totalHeight = rowHeights.reduce(0, +) + lineSpacing * CGFloat(rows.count - 1)

        let maxWidth = rows.map { row in
            computeRowWidth(indices: row, sizes: sizes)
        }.max() ?? 0

        return CGSize(width: maxWidth, height: totalHeight)
    }
}
