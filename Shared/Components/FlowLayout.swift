//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A custom layout that arranges views in a flow pattern, automatically wrapping items to new rows
struct FlowLayout: Layout {

    // MARK: - Fill Direction

    enum Direction {
        case up
        case down
    }

    // MARK: - Cache Structure

    struct CacheData {
        let subviewSizes: [CGSize]
        let rows: [[Int]]
        let totalSize: CGSize
        let lastWidth: CGFloat?
    }

    // MARK: - Properties

    /// The alignment of content within each row (leading, center, or trailing)
    private let alignment: HorizontalAlignment
    /// Controls whether items fill from the top row down or bottom row up when wrapping
    private let direction: Direction
    /// The horizontal spacing between items within the same row
    private let spacing: CGFloat
    /// The vertical spacing between the top and bottom rows when content wraps
    private let lineSpacing: CGFloat
    /// The minimum number of items that must be in the smaller row when wrapping occurs
    private let minRowLength: Int

    init(
        alignment: HorizontalAlignment = .center,
        direction: Direction = .up,
        spacing: CGFloat = 8,
        lineSpacing: CGFloat = 8,
        minRowLength: Int = 2
    ) {
        self.alignment = alignment
        self.direction = direction
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.minRowLength = minRowLength
    }

    // MARK: - Make Cache

    func makeCache(subviews: Subviews) -> CacheData {
        CacheData(
            subviewSizes: [],
            rows: [],
            totalSize: .zero,
            lastWidth: nil
        )
    }

    // MARK: - Update Cache

    func updateCache(_ cache: inout CacheData, subviews: Subviews) {
        cache = CacheData(
            subviewSizes: [],
            rows: [],
            totalSize: .zero,
            lastWidth: nil
        )
    }

    // MARK: - Calculate Layout

    private func calculateLayout(
        subviews: Subviews,
        width: CGFloat
    ) -> (sizes: [CGSize], rows: [[Int]], totalSize: CGSize) {
        let sizes = subviews.map { subview in
            let size = subview.sizeThatFits(.unspecified)
            return CGSize(width: ceil(size.width), height: ceil(size.height))
        }

        let rows = computeRows(sizes: sizes, maxWidth: width)
        let totalSize = computeTotalSize(rows: rows, sizes: sizes)

        return (sizes, rows, totalSize)
    }

    // MARK: - Size That Fits

    /// Calculates the minimum size needed to display all subviews according to the flow layout rules
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) -> CGSize {
        let availableWidth = proposal.width ?? .infinity
        let effectiveWidth = availableWidth.isFinite ? availableWidth : 1000

        if cache.lastWidth != effectiveWidth || cache.subviewSizes.isEmpty {
            let (sizes, rows, totalSize) = calculateLayout(
                subviews: subviews,
                width: effectiveWidth
            )

            cache = CacheData(
                subviewSizes: sizes,
                rows: rows,
                totalSize: totalSize,
                lastWidth: effectiveWidth
            )
        }

        // Return the calculated height but respect the proposed width
        return CGSize(
            width: min(cache.totalSize.width, proposal.width ?? cache.totalSize.width),
            height: cache.totalSize.height
        )
    }

    // MARK: - Place Subviews

    /// Positions each subview within the given bounds according to the flow layout rules
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) {
        let availableWidth = bounds.width

        if cache.lastWidth != availableWidth || cache.subviewSizes.isEmpty {
            let (sizes, rows, totalSize) = calculateLayout(
                subviews: subviews,
                width: availableWidth
            )

            cache = CacheData(
                subviewSizes: sizes,
                rows: rows,
                totalSize: totalSize,
                lastWidth: availableWidth
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
    private func computeRows(
        sizes: [CGSize],
        maxWidth: CGFloat
    ) -> [[Int]] {
        guard sizes.count > 1 else {
            return sizes.isEmpty ? [] : [[0]]
        }

        // First create rows by fitting items naturally
        let rows = createInitialRows(sizes: sizes, maxWidth: maxWidth)

        // Then optimize distribution based on flow direction
        return optimizeRowDistribution(rows: rows, sizes: sizes, maxWidth: maxWidth)
    }

    /// Create initial rows by fitting items sequentially
    private func createInitialRows(
        sizes: [CGSize],
        maxWidth: CGFloat
    ) -> [[Int]] {
        var rows: [[Int]] = []
        var currentRow: [Int] = []
        var currentWidth: CGFloat = 0

        for (index, size) in sizes.enumerated() {
            if currentRow.isEmpty {
                currentRow.append(index)
                currentWidth = size.width
            } else {
                let widthWithItem = currentWidth + spacing + size.width

                if widthWithItem <= maxWidth {
                    currentRow.append(index)
                    currentWidth = widthWithItem
                } else {
                    rows.append(currentRow)
                    currentRow = [index]
                    currentWidth = size.width
                }
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    /// Optimize row distribution based on flow direction
    private func optimizeRowDistribution(
        rows: [[Int]],
        sizes: [CGSize],
        maxWidth: CGFloat
    ) -> [[Int]] {
        guard rows.count > 1 else { return rows }

        var optimizedRows = rows

        switch direction {
        case .up:
            // Move items from earlier rows to later rows to create upward flow
            optimizedRows = balanceRowsForUpwardFlow(rows: optimizedRows, sizes: sizes, maxWidth: maxWidth)
        case .down:
            // Move items from later rows to earlier rows to create downward flow
            optimizedRows = balanceRowsForDownwardFlow(rows: optimizedRows, sizes: sizes, maxWidth: maxWidth)
        }

        return optimizedRows
    }

    /// Balance rows for upward flow - fill bottom rows more than top rows
    private func balanceRowsForUpwardFlow(
        rows: [[Int]],
        sizes: [CGSize],
        maxWidth: CGFloat
    ) -> [[Int]] {
        var optimizedRows = rows

        for i in 0 ..< optimizedRows.count - 1 {
            while optimizedRows[i].count > minRowLength {
                let lastItem = optimizedRows[i].last!

                var testRow = optimizedRows[i + 1]
                testRow.append(lastItem)
                let newWidth = computeRowWidth(indices: testRow, sizes: sizes)

                if newWidth <= maxWidth {
                    optimizedRows[i].removeLast()
                    optimizedRows[i + 1].append(lastItem)
                } else {
                    break
                }
            }
        }

        return optimizedRows
    }

    /// Balance rows for downward flow - fill top rows more than bottom rows
    private func balanceRowsForDownwardFlow(
        rows: [[Int]],
        sizes: [CGSize],
        maxWidth: CGFloat
    ) -> [[Int]] {
        var optimizedRows = rows

        for i in (0 ..< optimizedRows.count - 1).reversed() {
            while optimizedRows[i + 1].count > minRowLength {
                let firstItem = optimizedRows[i + 1].first!

                var testRow = optimizedRows[i]
                testRow.append(firstItem)
                let newWidth = computeRowWidth(indices: testRow, sizes: sizes)

                if newWidth <= maxWidth {
                    optimizedRows[i + 1].removeFirst()
                    optimizedRows[i].append(firstItem)
                } else {
                    break
                }
            }
        }

        return optimizedRows
    }

    // MARK: - Compute Row Width

    /// Calculates the total width needed for a row of items including spacing
    private func computeRowWidth(
        indices: [Int],
        sizes: [CGSize]
    ) -> CGFloat {
        guard indices.isNotEmpty else { return 0 }

        let itemsWidth = indices.reduce(0) { $0 + sizes[$1].width }
        let spacingWidth = spacing * CGFloat(indices.count - 1)

        return itemsWidth + spacingWidth
    }

    // MARK: - Compute X Offset

    /// Calculates the starting X position for a row based on the alignment setting
    private func computeXOffset(
        rowWidth: CGFloat,
        bounds: CGRect
    ) -> CGFloat {
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
    private func computeTotalSize(
        rows: [[Int]],
        sizes: [CGSize]
    ) -> CGSize {
        guard rows.isNotEmpty else { return .zero }

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
