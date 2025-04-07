//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct AttributeLayout: Layout {
        var alignment: Alignment = .center
        var spacing: CGFloat = 8
        var lineSpacing: CGFloat = 8

        // MARK: - Determine Total Size

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let maxWidth = proposal.width ?? .infinity
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            let (topRow, bottomRow) = determineRows(sizes: sizes, maxWidth: maxWidth)

            let topHeight = topRow.isEmpty ? 0 : topRow.map { sizes[$0].height }.max() ?? 0
            let bottomHeight = bottomRow.isEmpty ? 0 : bottomRow.map { sizes[$0].height }.max() ?? 0
            let totalHeight = topRow.isEmpty ? bottomHeight : topHeight + lineSpacing + bottomHeight

            let topWidth = topRow.isEmpty ? 0 : calculateRowWidth(indices: topRow, sizes: sizes)
            let bottomWidth = bottomRow.isEmpty ? 0 : calculateRowWidth(indices: bottomRow, sizes: sizes)

            return CGSize(width: max(topWidth, bottomWidth), height: totalHeight)
        }

        // MARK: - Place and Order Rows

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            let (topRow, bottomRow) = determineRows(sizes: sizes, maxWidth: bounds.width)

            let topHeight = topRow.isEmpty ? 0 : topRow.map { sizes[$0].height }.max() ?? 0
            let bottomHeight = bottomRow.isEmpty ? 0 : bottomRow.map { sizes[$0].height }.max() ?? 0

            let topWidth = topRow.isEmpty ? 0 : calculateRowWidth(indices: topRow, sizes: sizes)
            let bottomWidth = bottomRow.isEmpty ? 0 : calculateRowWidth(indices: bottomRow, sizes: sizes)

            /// Place top row (if needed)
            placeRow(
                bounds: bounds,
                subviews: subviews,
                indices: topRow,
                sizes: sizes,
                rowWidth: topWidth,
                rowHeight: topHeight,
                y: bounds.minY,
                alignment: alignment
            )

            /// Place bottom row
            placeRow(
                bounds: bounds,
                subviews: subviews,
                indices: bottomRow,
                sizes: sizes,
                rowWidth: bottomWidth,
                rowHeight: bottomHeight,
                y: bounds.minY + (topRow.isEmpty ? 0 : topHeight + lineSpacing),
                alignment: alignment
            )
        }

        // MARK: - Calculate Row Width

        private func calculateRowWidth(indices: [Int], sizes: [CGSize]) -> CGFloat {
            guard !indices.isEmpty else { return 0 }

            let itemsWidth = indices.reduce(0) { $0 + sizes[$1].width }
            return itemsWidth + spacing * CGFloat(indices.count - 1)
        }

        // MARK: - Place Row

        private func placeRow(
            bounds: CGRect,
            subviews: Subviews,
            indices: [Int],
            sizes: [CGSize],
            rowWidth: CGFloat,
            rowHeight: CGFloat,
            y: CGFloat,
            alignment: Alignment
        ) {
            guard !indices.isEmpty else { return }

            /// Starting x position based on alignment
            var startX: CGFloat
            switch alignment.horizontal {
            case .trailing:
                startX = bounds.maxX - rowWidth
            case .center:
                startX = bounds.minX + (bounds.width - rowWidth) / 2
            case .leading, _:
                startX = bounds.minX
            }

            var currentX = startX

            for (i, index) in indices.enumerated() {
                let itemSize = sizes[index]
                let itemY = y + (rowHeight - itemSize.height) / 2

                subviews[index].place(
                    at: CGPoint(x: currentX, y: itemY),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(itemSize)
                )

                /// Move to next item position with exact spacing
                currentX += itemSize.width
                if i < indices.count - 1 {
                    currentX += spacing
                }
            }
        }

        // MARK: - Determine Items per Row

        private func determineRows(sizes: [CGSize], maxWidth: CGFloat) -> ([Int], [Int]) {
            let itemCount = sizes.count

            /// Handle edge cases
            if itemCount == 0 { return ([], []) }
            if itemCount == 1 { return ([], [0]) }

            /// Calculate if all items can fit in one row
            let totalWidth = calculateRowWidth(indices: Array(0 ..< itemCount), sizes: sizes)

            /// If everything fits in one row, put all items in the bottom row
            if totalWidth <= maxWidth {
                return ([], Array(0 ..< itemCount))
            }

            /// We need two rows - first determine how many items to place in each row
            /// Try to maximize bottom row within width constraints
            var bottomRowCount = itemCount
            var bottomRowWidth = totalWidth

            while bottomRowCount > 0 {
                /// Remove one item from calculation
                bottomRowCount -= 1
                /// Recalculate width without this item
                let indices = Array((itemCount - bottomRowCount) ..< itemCount)
                bottomRowWidth = calculateRowWidth(indices: indices, sizes: sizes)

                /// If it now fits, we found our bottom row size
                if bottomRowWidth <= maxWidth {
                    break
                }
            }

            /// Ensure we have at least one item in bottom row
            bottomRowCount = max(1, bottomRowCount)

            /// Calculate how many go in top row (the rest)
            let topRowCount = itemCount - bottomRowCount

            /// Ensure at least 2 items are moved to top row if any are moved
            if topRowCount == 1 && itemCount >= 3 {
                bottomRowCount -= 1
            }

            /// Create the row arrays in original order
            let topRowIndices = Array(0 ..< (itemCount - bottomRowCount))
            let bottomRowIndices = Array((itemCount - bottomRowCount) ..< itemCount)

            return (topRowIndices, bottomRowIndices)
        }
    }
}
