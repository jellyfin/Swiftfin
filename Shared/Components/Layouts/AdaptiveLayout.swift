//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ViewLayout: Equatable {

    enum Presentation {

        case standard
        case large

        static var current: Self {
            #if os(tvOS)
            .large
            #else
            .standard
            #endif
        }
    }

    var size: CGSize = .zero
    var isRegularWidth: Bool = false
    var contentSizeCategory: UIContentSizeCategory = .large
    var presentation: Presentation = .current

    static let platformDefault = ViewLayout()

    var isLarge: Bool {
        presentation == .large
    }

    var isAccessibilitySize: Bool {
        contentSizeCategory.isAccessibilityCategory
    }

    var isCompact: Bool {
        isAccessibilitySize || (size.width > 0 ? size.width < 600 : !isRegularWidth)
    }

    var usesCompactDetail: Bool {
        isAccessibilitySize || (size.width > 0 ? size.width < 700 : !isRegularWidth)
    }

    var usesCompactPlayer: Bool {
        !isLarge && size.width < 600 && size.height >= 500
    }

    func value<Value>(compact: Value, regular: Value) -> Value {
        isCompact ? compact : regular
    }

    func value<Value>(standard: Value, large: Value) -> Value {
        isLarge ? large : standard
    }

    var edgePadding: CGFloat {
        value(standard: value(compact: 16, regular: 24), large: 60)
    }

    var edgeInsets: EdgeInsets {
        EdgeInsets(edgePadding)
    }

    var itemSpacing: CGFloat {
        value(standard: 10, large: 40)
    }

    var controlHeight: CGFloat {
        value(standard: 44, large: 75)
    }

    var selectionBorderWidth: CGFloat {
        value(standard: 8, large: 12)
    }

    var indicatorSize: CGFloat {
        value(standard: 25, large: 45)
    }

    var supplementLogoHeight: CGFloat {
        value(standard: 40, large: 80)
    }

    var supplementRowHeight: CGFloat {
        value(standard: 50, large: 80)
    }

    var toolbarButtonSize: CGFloat {
        value(standard: 44, large: 56)
    }

    var userGridColumns: AdaptiveColumns {
        AdaptiveColumns(minimumWidth: value(standard: 140, large: 250), maximumCount: 5, spacing: itemSpacing)
    }

    var canAdjustLibraryListColumns: Bool {
        libraryListColumns(maximumCount: 2).count(for: size.width) > 1
    }

    func libraryListColumns(maximumCount: Int) -> AdaptiveColumns {
        AdaptiveColumns(
            minimumWidth: value(standard: 300, large: 500),
            maximumCount: maximumCount,
            spacing: value(standard: 0, large: itemSpacing)
        )
    }

    func posterMinimumWidth(for displayType: PosterDisplayType, size: PosterDisplayType.Size = .small) -> CGFloat {
        let usesCompactPosters = isCompact && !isLarge && !isAccessibilitySize

        let width: CGFloat = switch (displayType, size) {
        case (.landscape, .small):
            usesCompactPosters ? 160 : 180
        case (.landscape, .medium):
            usesCompactPosters ? 220 : 300
        case (_, .small):
            usesCompactPosters ? 110 : 120
        default:
            usesCompactPosters ? 160 : 200
        }

        return value(standard: width, large: width * 1.5)
    }

    var supplementButtonSpacing: CGFloat {
        value(standard: 10, large: 20)
    }

    var toolbarButtonSpacing: CGFloat {
        UIDevice.supportsLiquidGlass ? value(standard: 4, large: 20) : value(standard: 0, large: 16)
    }

    func resolving(size: CGSize) -> Self {
        var result = self
        result.size = size
        return result
    }

    func scrollContentEdges(extendsTop: Bool) -> Edge.Set {
        var edges: Edge.Set = isLarge ? .horizontal : []
        if extendsTop {
            edges.insert(.top)
        }
        return edges
    }

    init(
        size: CGSize = .zero,
        isRegularWidth: Bool = false,
        contentSizeCategory: UIContentSizeCategory = .large,
        presentation: Presentation = .current
    ) {
        self.size = size
        self.isRegularWidth = isRegularWidth
        self.contentSizeCategory = contentSizeCategory
        self.presentation = presentation
    }

    init(size: CGSize, traits: UITraitCollection) {
        self.init(
            size: size,
            isRegularWidth: traits.horizontalSizeClass == .regular,
            contentSizeCategory: traits.preferredContentSizeCategory
        )
    }
}

@propertyWrapper
struct AdaptiveLayout: DynamicProperty {

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize
    @Environment(\.frameForParentView[.layoutContainer])
    private var containerFrame

    var wrappedValue: ViewLayout {
        ViewLayout(
            size: containerFrame?.frame.size ?? .zero,
            isRegularWidth: horizontalSizeClass == .regular,
            contentSizeCategory: dynamicTypeSize.contentSizeCategory
        )
    }
}

private extension DynamicTypeSize {

    var contentSizeCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        case .xxxLarge: .extraExtraExtraLarge
        case .accessibility1: .accessibilityMedium
        case .accessibility2: .accessibilityLarge
        case .accessibility3: .accessibilityExtraLarge
        case .accessibility4: .accessibilityExtraExtraLarge
        case .accessibility5: .accessibilityExtraExtraExtraLarge
        @unknown default: .large
        }
    }
}

struct EdgePaddingModifier: ViewModifier {

    @AdaptiveLayout
    private var viewLayout

    let edges: Edge.Set

    func body(content: Content) -> some View {
        content.padding(edges, viewLayout.edgePadding)
    }
}

extension View {

    func layoutContainer(size: CGSize) -> some View {
        transformEnvironment(\.frameForParentView) { frames in
            frames[.layoutContainer] = .init(frame: CGRect(origin: .zero, size: size), safeAreaInsets: .zero)
        }
    }
}
