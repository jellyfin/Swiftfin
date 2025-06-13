//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FlowLayout: Layout {

    // MARK: - Fill Direction

    /// Controls the priority order when distributing items across rows
    enum FillDirection {
        case topDown
        case bottomUp
    }

    // MARK: - Cache Structure

    /// Stores computed layout values to avoid redundant calculations between layout passes
    struct CacheData {
        let subviewSizes: [CGSize]
        let rows: [[Int]]
        let totalSize: CGSize
        let lastProposal: ProposedViewSize?
        let lastBounds: CGRect?
    }

    // MARK: - Properties

    /// The alignment of content within each row (leading, center, or trailing)
    var alignment: HorizontalAlignment = .center
    /// The horizontal spacing between items within the same row
    var spacing: CGFloat = 8
    /// The vertical spacing between the top and bottom rows when content wraps
    var lineSpacing: CGFloat = 8
    /// Controls whether items fill from the top row down or bottom row up when wrapping
    var fillDirection: FillDirection = .bottomUp

    // MARK: - Make Cache

    /// Creates initial cache storage for layout computations
    func makeCache(subviews: Subviews) -> CacheData {
        CacheData(
            subviewSizes: [],
            rows: [],
            totalSize: .zero,
            lastProposal: nil,
            lastBounds: nil
        )
    }

    // MARK: - Update Cache

    /// Resets cache when subviews change
    func updateCache(_ cache: inout CacheData, subviews: Subviews) {
        cache = CacheData(
            subviewSizes: [],
            rows: [],
            totalSize: .zero,
            lastProposal: nil,
            lastBounds: nil
        )
    }

    // MARK: - Size That Fits

    /// Calculates the minimum size needed to display all subviews according to the flow layout rules
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        if cache.lastProposal != proposal || cache.subviewSizes.isEmpty {
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            let maxWidth = proposal.width ?? .infinity
            let rows = computeRows(sizes: sizes, maxWidth: maxWidth)
            let totalSize = computeTotalSize(rows: rows, sizes: sizes)

            cache = CacheData(
                subviewSizes: sizes,
                rows: rows,
                totalSize: totalSize,
                lastProposal: proposal,
                lastBounds: cache.lastBounds
            )
        }

        return cache.totalSize
    }

    // MARK: - Place Subviews

    /// Positions each subview within the given bounds according to the flow layout rules
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        if cache.lastBounds != bounds || cache.lastProposal != proposal || cache.subviewSizes.isEmpty {
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            let rows = computeRows(sizes: sizes, maxWidth: bounds.width)

            cache = CacheData(
                subviewSizes: sizes,
                rows: rows,
                totalSize: cache.totalSize,
                lastProposal: proposal,
                lastBounds: bounds
            )
        }

        let sizes = cache.subviewSizes
        let rows = cache.rows

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

    /// Determines how to distribute items across rows based on the available width
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

    /// Determine the index where the items should be moved to a second row
    private func findSplitIndex(sizes: [CGSize], maxWidth: CGFloat) -> Int {
        switch fillDirection {

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

    /// Calculates the total width needed for a row of items including spacing
    private func computeRowWidth(indices: [Int], sizes: [CGSize]) -> CGFloat {
        guard !indices.isEmpty else { return 0 }

        let itemsWidth = indices.reduce(0) { $0 + sizes[$1].width }
        let spacingWidth = spacing * CGFloat(indices.count - 1)

        return itemsWidth + spacingWidth
    }

    // MARK: - Compute X Offset

    /// Calculates the starting X position for a row based on the alignment setting
    private func computeXOffset(rowWidth: CGFloat, bounds: CGRect) -> CGFloat {
        switch alignment {
        case .trailing:
            return bounds.maxX - rowWidth
        case .center:
            return bounds.minX + (bounds.width - rowWidth) / 2
        default:
            return bounds.minX
        }
    }

    // MARK: - Compute Total Size

    /// Calculates the total size needed to display all rows with proper spacing
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
