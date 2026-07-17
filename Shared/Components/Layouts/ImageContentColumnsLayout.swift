//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ImageContentColumnsLayout: Layout {

    private struct Measurements {
        let contentSize: CGSize
        let contentWidth: CGFloat
        let imageHeight: CGFloat
        let imageWidth: CGFloat
        let spacing: CGFloat

        var height: CGFloat {
            max(imageHeight, contentSize.height)
        }
    }

    let idealContentWidth: CGFloat
    let imageAspectRatio: CGFloat
    let imageColumnFraction: CGFloat
    let spacing: CGFloat

    private func resolvedWidth(
        for proposal: ProposedViewSize
    ) -> CGFloat {
        if let proposedWidth = proposal.width, proposedWidth.isFinite {
            return max(0, proposedWidth)
        }

        return idealContentWidth + spacing
    }

    private func measurements(
        for width: CGFloat,
        subviews: Subviews
    ) -> Measurements {
        let availableWidth = max(0, width)
        let resolvedSpacing = min(spacing, availableWidth)
        let columnsWidth = availableWidth - resolvedSpacing
        let resolvedImageColumnFraction = min(max(imageColumnFraction, 0), 1)
        let imageWidth = columnsWidth * resolvedImageColumnFraction
        let contentWidth = columnsWidth - imageWidth
        let imageHeight = imageWidth / imageAspectRatio
        let contentSize = subviews[1].sizeThatFits(
            ProposedViewSize(width: contentWidth, height: nil)
        )

        return Measurements(
            contentSize: contentSize,
            contentWidth: contentWidth,
            imageHeight: imageHeight,
            imageWidth: imageWidth,
            spacing: resolvedSpacing
        )
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard subviews.count == 2 else { return .zero }

        let width = resolvedWidth(for: proposal)
        let measurements = measurements(for: width, subviews: subviews)

        return CGSize(width: width, height: measurements.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard subviews.count == 2 else { return }

        let measurements = measurements(for: bounds.width, subviews: subviews)
        let imageY: CGFloat
        let contentY: CGFloat

        if measurements.imageHeight > measurements.contentSize.height {
            imageY = bounds.minY
            contentY = bounds.minY + measurements.imageHeight - measurements.contentSize.height
        } else {
            imageY = bounds.minY + (measurements.contentSize.height - measurements.imageHeight) / 2
            contentY = bounds.minY
        }

        subviews[0].place(
            at: CGPoint(x: bounds.minX, y: imageY),
            anchor: .topLeading,
            proposal: ProposedViewSize(
                width: measurements.imageWidth,
                height: measurements.imageHeight
            )
        )
        subviews[1].place(
            at: CGPoint(
                x: bounds.minX + measurements.imageWidth + measurements.spacing,
                y: contentY
            ),
            anchor: .topLeading,
            proposal: ProposedViewSize(
                width: measurements.contentWidth,
                height: measurements.contentSize.height
            )
        )
    }
}
