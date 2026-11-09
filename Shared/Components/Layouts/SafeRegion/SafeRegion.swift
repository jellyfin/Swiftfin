//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@OptionSet<Int>
struct SafeRegionAreas: OptionSet {

    private enum Options: Int {
        case custom
        case system
    }

    static let all: Self = [.custom, .system]
}

enum SafeRegionSystemInsets {

    /// Use the local GeometryProxy's safe area.
    case automatic

    /// Use insets captured before native safe-area handling was disabled.
    case forwarded(EdgeInsets)

    /// Apply no system insets.
    case none
}

/// Create a SafeRegion with a specific ID type to allow items to observe named insets.
struct SafeRegion<ID: Hashable, Content: View>: View {

    private let systemInsets: SafeRegionSystemInsets
    private let content: Content

    init(
        _ idType: ID.Type = Never.self,
        systemInsets: SafeRegionSystemInsets = .automatic,
        @ViewBuilder content: () -> Content
    ) {
        self.systemInsets = systemInsets
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            RegionLayout<ID>(systemInsets: resolvedInsets(geometry)) {
                content
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }

    private func resolvedInsets(_ geometry: GeometryProxy) -> EdgeInsets {
        switch systemInsets {
        case .automatic: geometry.safeAreaInsets
        case let .forwarded(value): value
        case .none: EdgeInsets()
        }
    }
}

/// Aligns content in the remaining region. Oversized content is centered and
/// clipped unless `clipsContent` is false.
struct SafeRegionItem<ID: Hashable, Content: View>: View {

    private let alignment: Alignment
    private let clipsContent: Bool
    private let content: Content
    private var ignoredCustom: Edge.Set = []
    private var ignoredSystem: Edge.Set = []
    private var observedRegions: Set<ID>?

    init(
        _ idType: ID.Type = Never.self,
        alignment: Alignment = .center,
        clipsContent: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.clipsContent = clipsContent
        self.content = content()
    }

    func observingSafeRegion(_ regions: Set<ID>?) -> Self {
        with(self) {
            $0.observedRegions = regions
        }
    }

    func ignoresSafeRegion(_ areas: SafeRegionAreas = .custom, edges: Edge.Set = .all) -> Self {
        with(self) {
            if areas.contains(.custom) {
                $0.ignoredCustom.formUnion(edges)
            }

            if areas.contains(.system) {
                $0.ignoredSystem.formUnion(edges)
            }
        }
    }

    var body: some View {
        BoundedContentLayout(fillsProposal: true, anchor: regionAnchor(alignment)) {
            ZStack(alignment: alignment) { content }
        }
        .modifier(RegionClipping(isEnabled: clipsContent))
        .layoutValue(key: RegionRoleKey.self, value: .item(ignoredCustom, ignoredSystem))
        .layoutValue(key: ObservedRegionIDsKey<ID>.self, value: observedRegions)
    }
}

struct SafeRegionInset<ID: Hashable, Content: View>: View {

    private let edge: Edge
    private let spacing: CGFloat
    private let id: ID?
    private let isActive: Bool
    private let clipsContent: Bool
    private let content: Content
    private var ignoredSystem: Edge.Set = []

    init(
        edge: Edge,
        spacing: CGFloat = 0,
        id: ID? = Never?.none,
        isActive: Bool = true,
        clipsContent: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.edge = edge
        self.spacing = spacing
        self.id = id
        self.isActive = isActive
        self.clipsContent = clipsContent
        self.content = content()
    }

    func ignoresSystemSafeRegion(edges: Edge.Set) -> Self {
        with(self) {
            $0.ignoredSystem.formUnion(edges)
        }
    }

    var body: some View {
        BoundedContentLayout(fillsProposal: false, anchor: regionAnchor(edge.alignment)) {
            content
        }
        .modifier(RegionClipping(isEnabled: clipsContent))
        .layoutValue(key: RegionRoleKey.self, value: .inset(edge, spacing, isActive, ignoredSystem))
        .layoutValue(key: RegionIDKey<ID>.self, value: id)
    }
}

private enum RegionRole {
    case item(Edge.Set, Edge.Set)
    case inset(Edge, CGFloat, Bool, Edge.Set)
}

private struct RegionRoleKey: LayoutValueKey {
    static let defaultValue = RegionRole.item([], [])
}

private struct RegionIDKey<ID: Hashable>: LayoutValueKey {
    static var defaultValue: ID? {
        nil
    }
}

private struct ObservedRegionIDsKey<ID: Hashable>: LayoutValueKey {
    static var defaultValue: Set<ID>? {
        nil
    }
}

private struct RegionClipping: ViewModifier {

    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.clipped()
        } else {
            content
        }
    }
}

private struct RegionLayout<ID: Hashable>: Layout {

    let systemInsets: EdgeInsets

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        finiteSize(proposal.replacingUnspecifiedDimensions())
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {

        // SwiftUI mirrors these logical coordinates in RTL.
        var geometry = RegionGeometry<ID>(size: bounds.size, systemInsets: systemInsets)

        // Measure reservations before placing their observers.
        for child in subviews {
            guard case let .inset(edge, spacing, isActive, ignoredSystem) = child[RegionRoleKey.self] else { continue }

            let available = geometry.region(ignoringSystem: ignoredSystem)
            let vertical = edge == .top || edge == .bottom

            // Measure intrinsic thickness along the reserved edge.
            let measurement = ProposedViewSize(
                width: vertical ? available.width : nil,
                height: vertical ? nil : available.height
            )

            let size = finiteSize(child.sizeThatFits(measurement))
            var candidate = geometry

            let frame = candidate.reserve(
                edge: edge, thickness: vertical ? size.height : size.width,
                spacing: spacing, id: child[RegionIDKey<ID>.self], ignoringSystem: ignoredSystem
            )

            // Inactive controls stay mounted but reserve no space.
            if isActive {
                geometry = candidate
            }

            child.place(
                at: CGPoint(x: bounds.minX + frame.midX, y: bounds.minY + frame.midY),
                anchor: .center,
                proposal: ProposedViewSize(frame.size)
            )
        }

        for child in subviews {
            guard case let .item(custom, system) = child[RegionRoleKey.self] else { continue }

            let frame = geometry.region(
                ignoringCustom: custom, ignoringSystem: system,
                observing: child[ObservedRegionIDsKey<ID>.self]
            )

            child.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(frame.size)
            )
        }
    }
}

private func regionAnchor(_ alignment: Alignment) -> UnitPoint {
    let logicalX: CGFloat = alignment.horizontal == .leading ? 0 : alignment.horizontal == .trailing ? 1 : 0.5
    let y: CGFloat = alignment.vertical == .top ? 0 : alignment.vertical == .bottom ? 1 : 0.5
    return UnitPoint(x: logicalX, y: y)
}
