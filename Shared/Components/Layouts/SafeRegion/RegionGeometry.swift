//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct RegionInsets: Equatable {

    var top: CGFloat = 0
    var leading: CGFloat = 0
    var bottom: CGFloat = 0
    var trailing: CGFloat = 0

    init(_ value: EdgeInsets = EdgeInsets()) {
        top = finiteLength(value.top)
        leading = finiteLength(value.leading)
        bottom = finiteLength(value.bottom)
        trailing = finiteLength(value.trailing)
    }

    subscript(edge: Edge) -> CGFloat {
        get {
            switch edge {
            case .top: top
            case .leading: leading
            case .bottom: bottom
            case .trailing: trailing
            }
        }
        set {
            switch edge {
            case .top: top = newValue
            case .leading: leading = newValue
            case .bottom: bottom = newValue
            case .trailing: trailing = newValue
            }
        }
    }
}

func finiteLength(_ value: CGFloat) -> CGFloat {
    value.isFinite ? max(0, value) : 0
}

func finiteSize(_ size: CGSize) -> CGSize {
    CGSize(width: finiteLength(size.width), height: finiteLength(size.height))
}

struct RegionGeometry<ID: Hashable> {
    let size: CGSize
    let direction: LayoutDirection
    let system: RegionInsets
    private var reservations: [ID?: RegionInsets] = [:]

    init(size: CGSize, systemInsets: EdgeInsets, direction: LayoutDirection = .leftToRight) {
        self.size = finiteSize(size)
        self.direction = direction
        self.system = RegionInsets(systemInsets)
    }

    /// Reserves an edge and its spacing. Empty content reserves neither.
    mutating func reserve(
        edge: Edge, thickness: CGFloat, spacing: CGFloat,
        id: ID? = nil, ignoringSystem: Edge.Set = []
    ) -> CGRect {
        let remaining = region(ignoringSystem: ignoringSystem)
        let vertical = edge == .top || edge == .bottom
        let available = vertical ? remaining.height : remaining.width
        let length = min(finiteLength(thickness), available)
        var frame = remaining
        let isLowEdge = edge == .top ||
            (edge == .leading && direction == .leftToRight) ||
            (edge == .trailing && direction == .rightToLeft)

        if vertical {
            frame.size.height = length
            if !isLowEdge {
                frame.origin.y = remaining.maxY - length
            }
        } else {
            frame.size.width = length
            if !isLowEdge {
                frame.origin.x = remaining.maxX - length
            }
        }
        guard length > 0 else { return frame }

        let consumed = length + min(finiteLength(spacing), available - length)
        // Include the system gap so ignoring it cannot expose reserved controls.
        let boundary: CGFloat = switch edge {
        case .top: remaining.minY
        case .bottom: size.height - remaining.maxY
        case .leading: direction == .leftToRight ? remaining.minX : size.width - remaining.maxX
        case .trailing: direction == .leftToRight ? size.width - remaining.maxX : remaining.minX
        }
        let previousBoundary = reservations[id]?[edge] ?? 0
        reservations[id, default: RegionInsets()][edge] = max(previousBoundary, boundary + consumed)
        return frame
    }

    func region(
        ignoringCustom: Edge.Set = [], ignoringSystem: Edge.Set = [],
        observing: Set<ID>? = nil
    ) -> CGRect {
        let selected = reservations.filter { id, _ in
            guard let observing else { return true }
            guard let id else { return false }

            return observing.contains(id)
        }
        .values
        var effective = RegionInsets()
        for edge in [Edge.top, .leading, .bottom, .trailing] {
            let set = Edge.Set(edge)
            let systemValue = ignoringSystem.contains(set) ? 0 : system[edge]
            let customValue = ignoringCustom.contains(set) ? 0 : selected.reduce(0) { max($0, $1[edge]) }
            effective[edge] = max(systemValue, customValue)
        }
        return Self.rect(size: size, insets: effective, direction: direction)
    }

    static func rect(size: CGSize, insets: RegionInsets, direction: LayoutDirection) -> CGRect {
        let top = min(insets.top, size.height)
        let bottom = min(insets.bottom, size.height - top)
        let leading = min(insets.leading, size.width)
        let trailing = min(insets.trailing, size.width - leading)
        return CGRect(
            x: direction == .leftToRight ? leading : trailing,
            y: top,
            width: size.width - leading - trailing,
            height: size.height - top - bottom
        )
    }
}

/// Bounds content that refuses a smaller size proposal.
struct BoundedContentLayout: Layout {
    var fillsProposal: Bool
    var anchor: UnitPoint

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let natural = finiteSize(subviews.first?.sizeThatFits(proposal) ?? .zero)
        func dimension(_ proposed: CGFloat?, natural: CGFloat) -> CGFloat {
            guard let proposed, proposed.isFinite else { return natural }

            return fillsProposal ? finiteLength(proposed) : min(natural, finiteLength(proposed))
        }
        return CGSize(
            width: dimension(proposal.width, natural: natural.width),
            height: dimension(proposal.height, natural: natural.height)
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let child = subviews.first else { return }

        let constrained = ProposedViewSize(finiteSize(bounds.size))
        let measured = finiteSize(child.sizeThatFits(constrained))
        // Center oversized content on each overflowing axis.
        let x = bounds.minX + (bounds.width - measured.width) * (measured.width > bounds.width ? 0.5 : anchor.x)
        let y = bounds.minY + (bounds.height - measured.height) * (measured.height > bounds.height ? 0.5 : anchor.y)
        child.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: constrained)
    }
}
