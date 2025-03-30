//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {
    @available(iOS 16.0, *)
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

            /// Items don't all fit in one row use 2 rows
            /// Calculate how many items can fit in the bottom row
            var itemsInBottomRow = 0
            var availableWidth = maxWidth

            /// Start from the beginning (in reverse-ish order)
            for i in 0 ..< itemCount {
                let itemWidth = sizes[i].width
                let spaceNeeded = itemWidth + (itemsInBottomRow > 0 ? spacing : 0)

                if spaceNeeded <= availableWidth {
                    itemsInBottomRow += 1
                    availableWidth -= spaceNeeded
                } else {
                    break
                }
            }

            /// Start from the beginning (in standard order)
            let bottomRowSize = min(itemsInBottomRow, itemCount)
            let topRowSize = itemCount - bottomRowSize

            return (Array(0 ..< topRowSize), Array(topRowSize ..< itemCount))
        }
    }
}
