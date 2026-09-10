//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(macOS)
import SwiftUI

struct CollectionVGridLayout: Equatable {

    enum LayoutType: Equatable {
        case columns
        case minWidth
    }

    let insets: EdgeInsets
    let itemSpacing: CGFloat
    let lineSpacing: CGFloat
    let layoutValue: CGFloat
    let layoutType: LayoutType

    private init(
        insets: EdgeInsets,
        itemSpacing: CGFloat,
        lineSpacing: CGFloat,
        layoutValue: CGFloat,
        layoutType: LayoutType
    ) {
        self.insets = insets
        self.itemSpacing = itemSpacing
        self.lineSpacing = lineSpacing
        self.layoutValue = layoutValue
        self.layoutType = layoutType
    }

    static func columns(
        _ columns: Int,
        insets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10),
        itemSpacing: CGFloat = 10,
        lineSpacing: CGFloat = 10
    ) -> Self {
        .init(
            insets: insets,
            itemSpacing: itemSpacing,
            lineSpacing: lineSpacing,
            layoutValue: CGFloat(max(columns, 1)),
            layoutType: .columns
        )
    }

    static func minWidth(
        _ minWidth: CGFloat,
        insets: EdgeInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10),
        itemSpacing: CGFloat = 10,
        lineSpacing: CGFloat = 10
    ) -> Self {
        .init(
            insets: insets,
            itemSpacing: itemSpacing,
            lineSpacing: lineSpacing,
            layoutValue: minWidth,
            layoutType: .minWidth
        )
    }
}

struct CollectionVGridLocation {}

enum CollectionVGridEdgeOffset {
    case offset(CGFloat)
}

final class CollectionVGridProxy: ObservableObject {

    private var scrollToTopAction: ((Bool) -> Void)?

    func redraw() {
        objectWillChange.send()
    }

    func layout() {
        redraw()
    }

    func scrollToTop(animated: Bool = true) {
        scrollToTopAction?(animated)
    }

    fileprivate func setScrollToTopAction(_ action: ((Bool) -> Void)?) {
        scrollToTopAction = action
    }
}

struct CollectionVGrid<Element, Data: Collection, ID: Hashable, Content: View>: View where Data.Element == Element, Data.Index == Int {

    private let id: KeyPath<Element, ID>
    private let data: Data
    private let layout: CollectionVGridLayout
    private let viewProvider: (Element, CollectionVGridLocation) -> Content
    private var onReachedBottomEdgeAction: () -> Void = {}
    private var onReachedTopEdgeAction: () -> Void = {}
    private var bottomEdgeOffset: CGFloat = 0
    private var topEdgeOffset: CGFloat = 0
    private var collectionProxy: CollectionVGridProxy?

    private init(
        id: KeyPath<Element, ID>,
        data: Data,
        layout: CollectionVGridLayout,
        @ViewBuilder viewProvider: @escaping (Element, CollectionVGridLocation) -> Content
    ) {
        self.id = id
        self.data = data
        self.layout = layout
        self.viewProvider = viewProvider
    }

    init(
        uniqueElements: Data,
        id: KeyPath<Element, ID>,
        layout: CollectionVGridLayout,
        @ViewBuilder viewProvider: @escaping (Element, CollectionVGridLocation) -> Content
    ) {
        self.init(id: id, data: uniqueElements, layout: layout, viewProvider: viewProvider)
    }

    init(
        uniqueElements: Data,
        id: KeyPath<Element, ID>,
        layout: CollectionVGridLayout,
        @ViewBuilder viewProvider: @escaping (Element) -> Content
    ) {
        self.init(id: id, data: uniqueElements, layout: layout) { element, _ in
            viewProvider(element)
        }
    }

    init(
        uniqueElements: Data,
        layout: CollectionVGridLayout,
        @ViewBuilder viewProvider: @escaping (Element, CollectionVGridLocation) -> Content
    ) where Element: Identifiable, ID == Element.ID {
        self.init(id: \.id, data: uniqueElements, layout: layout, viewProvider: viewProvider)
    }

    init(
        uniqueElements: Data,
        layout: CollectionVGridLayout,
        @ViewBuilder viewProvider: @escaping (Element) -> Content
    ) where Element: Identifiable, ID == Element.ID {
        self.init(id: \.id, data: uniqueElements, layout: layout) { element, _ in
            viewProvider(element)
        }
    }

    init(
        count: Int,
        layout: CollectionVGridLayout,
        @ViewBuilder viewProvider: @escaping (Int) -> Content
    ) where Data == [Element], Element == Int, ID == Int {
        self.init(id: \.self, data: Array(0 ..< count), layout: layout) { element, _ in
            viewProvider(element)
        }
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .id(CollectionGridMarker.top)
                        .offset(y: topEdgeOffset)
                        .onAppear(perform: onReachedTopEdgeAction)

                    LazyVGrid(columns: gridItems, alignment: .leading, spacing: layout.lineSpacing) {
                        ForEach(Array(data.enumerated()), id: \.offset) { _, element in
                            viewProvider(element, CollectionVGridLocation())
                                .id(element[keyPath: id])
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(layout.insets)

                    Color.clear
                        .frame(height: 1)
                        .id(CollectionGridMarker.bottom)
                        .offset(y: -bottomEdgeOffset)
                        .onAppear(perform: onReachedBottomEdgeAction)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .macScrollers(.overlay)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                collectionProxy?.setScrollToTopAction { animated in
                    if animated {
                        withAnimation {
                            scrollProxy.scrollTo(CollectionGridMarker.top, anchor: .top)
                        }
                    } else {
                        scrollProxy.scrollTo(CollectionGridMarker.top, anchor: .top)
                    }
                }
            }
        }
    }

    private var gridItems: [GridItem] {
        switch layout.layoutType {
        case .columns:
            Array(repeating: GridItem(.flexible(), spacing: layout.itemSpacing), count: max(Int(layout.layoutValue), 1))
        case .minWidth:
            [GridItem(.adaptive(minimum: max(layout.layoutValue, 1)), spacing: layout.itemSpacing)]
        }
    }

    private enum CollectionGridMarker: Hashable {
        case top
        case bottom
    }

    func onReachedBottomEdge(
        offset: CollectionVGridEdgeOffset = .offset(0),
        action: @escaping () -> Void
    ) -> Self {
        var copy = self
        if case let .offset(value) = offset {
            copy.bottomEdgeOffset = value
        }
        copy.onReachedBottomEdgeAction = action
        return copy
    }

    func onReachedTopEdge(
        offset: CollectionVGridEdgeOffset = .offset(0),
        action: @escaping () -> Void
    ) -> Self {
        var copy = self
        if case let .offset(value) = offset {
            copy.topEdgeOffset = value
        }
        copy.onReachedTopEdgeAction = action
        return copy
    }

    func proxy(_ proxy: CollectionVGridProxy) -> Self {
        var copy = self
        copy.collectionProxy = proxy
        return copy
    }
}

enum CollectionHStackLayout: Equatable {
    case grid(columns: CGFloat, rows: Int, columnTrailingInset: CGFloat)
    case minimumWidth(columnWidth: CGFloat, rows: Int)
    case selfSizingSameSize(rows: Int)
    case selfSizingVariadicWidth(rows: Int)
}

enum CollectionHStackEdgeOffset {
    case columns(Int)
    case offset(CGFloat)
}

enum CollectionHStackScrollBehavior {
    case columnPaging
    case continuous
    case continuousLeadingEdge
    case fullPaging
}

final class CollectionHStackProxy: ObservableObject {

    private var scrollToIndexAction: ((Int, Bool) -> Void)?
    private var scrollToIDAction: ((AnyHashable, Bool) -> Void)?

    func scrollTo(index: Int, animated: Bool = true) {
        scrollToIndexAction?(index, animated)
    }

    func scrollTo(id: some Hashable, animated: Bool = true) {
        scrollToIDAction?(AnyHashable(id), animated)
    }

    func redraw() {
        objectWillChange.send()
    }

    fileprivate func setScrollToIndexAction(_ action: ((Int, Bool) -> Void)?) {
        scrollToIndexAction = action
    }

    fileprivate func setScrollToIDAction(_ action: ((AnyHashable, Bool) -> Void)?) {
        scrollToIDAction = action
    }
}

private enum CollectionHStackMarker: Hashable {
    case leading
}

private enum CollectionHStackPageDirection {
    case backward
    case forward
}

/// Scroll metrics that only the paging buttons read, held in a reference type
/// so that tracking the offset during a scroll doesn't invalidate the row.
private final class CollectionHStackPageMetrics {

    var offset: CGFloat = 0
    var viewportWidth: CGFloat = 0
}

struct CollectionHStack<Element, Data: Collection, ID: Hashable, Content: View>: View where Data.Element == Element, Data.Index == Int {

    private let id: KeyPath<Element, ID>
    private let data: Data
    private let layout: CollectionHStackLayout
    private let viewProvider: (Element) -> Content
    private var horizontalInsets: EdgeInsets = .init(top: 0, leading: 15, bottom: 0, trailing: 15)
    private var itemSpacingValue: CGFloat = 10
    private var collectionProxy: CollectionHStackProxy?

    @State
    private var metrics = CollectionHStackPageMetrics()
    @State
    private var isHovering = false
    @State
    private var canPageBackward = false
    @State
    private var canPageForward = false

    private init(
        id: KeyPath<Element, ID>,
        data: Data,
        layout: CollectionHStackLayout,
        @ViewBuilder viewProvider: @escaping (Element) -> Content
    ) {
        self.id = id
        self.data = data
        self.layout = layout
        self.viewProvider = viewProvider
    }

    init(
        uniqueElements: Data,
        id: KeyPath<Element, ID>,
        layout: CollectionHStackLayout,
        @ViewBuilder content: @escaping (Element) -> Content
    ) {
        self.init(id: id, data: uniqueElements, layout: layout, viewProvider: content)
    }

    init(
        uniqueElements: Data,
        id: KeyPath<Element, ID>,
        columns: CGFloat,
        rows: Int = 1,
        columnTrailingInset: CGFloat = 0,
        @ViewBuilder content: @escaping (Element) -> Content
    ) {
        self.init(
            id: id,
            data: uniqueElements,
            layout: .grid(columns: columns, rows: rows, columnTrailingInset: columnTrailingInset),
            viewProvider: content
        )
    }

    init(
        uniqueElements: Data,
        id: KeyPath<Element, ID>,
        minWidth: CGFloat,
        rows: Int = 1,
        @ViewBuilder content: @escaping (Element) -> Content
    ) {
        self.init(
            id: id,
            data: uniqueElements,
            layout: .minimumWidth(columnWidth: minWidth, rows: rows),
            viewProvider: content
        )
    }

    // The layout initializer above is the designated public overload.

    init(
        uniqueElements: Data,
        columns: CGFloat,
        rows: Int = 1,
        columnTrailingInset: CGFloat = 0,
        @ViewBuilder content: @escaping (Element) -> Content
    ) where Element: Identifiable, ID == Element.ID {
        self.init(
            id: \.id,
            data: uniqueElements,
            layout: .grid(columns: columns, rows: rows, columnTrailingInset: columnTrailingInset),
            viewProvider: content
        )
    }

    init(
        uniqueElements: Data,
        layout: CollectionHStackLayout,
        @ViewBuilder content: @escaping (Element) -> Content
    ) where Element: Identifiable, ID == Element.ID {
        self.init(id: \.id, data: uniqueElements, layout: layout, viewProvider: content)
    }

    init(
        count: Int,
        columns: CGFloat,
        rows: Int = 1,
        columnTrailingInset: CGFloat = 0,
        @ViewBuilder content: @escaping (Int) -> Content
    ) where Data == [Element], Element == Int, ID == Int {
        self.init(
            id: \.self,
            data: Array(0 ..< count),
            layout: .grid(columns: columns, rows: rows, columnTrailingInset: columnTrailingInset),
            viewProvider: content
        )
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: 0)
                        .id(CollectionHStackMarker.leading)

                    LazyHGrid(rows: gridItems, alignment: .top, spacing: itemSpacingValue) {
                        ForEach(Array(data.enumerated()), id: \.offset) { _, element in
                            itemView(for: element)
                                .id(element[keyPath: id])
                        }
                    }
                    .padding(horizontalInsets)
                    .padding(.trailing, columnTrailingInset)
                }
                .macScrollers(.none, axes: .horizontal)
            }
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.x + geometry.contentInsets.leading
            } action: { _, offset in
                updatePaging(offset: offset, viewportWidth: metrics.viewportWidth)
            }
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            updatePaging(offset: metrics.offset, viewportWidth: proxy.size.width)
                        }
                        .onChange(of: proxy.size.width) { _, newWidth in
                            updatePaging(offset: metrics.offset, viewportWidth: newWidth)
                        }
                }
            }
            .overlay(alignment: .leading) {
                pageButton(systemImage: "chevron.left", isAvailable: canPageBackward) {
                    page(.backward, scrollProxy: scrollProxy)
                }
            }
            .overlay(alignment: .trailing) {
                pageButton(systemImage: "chevron.right", isAvailable: canPageForward) {
                    page(.forward, scrollProxy: scrollProxy)
                }
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hovering
                }
            }
            .onAppear {
                collectionProxy?.setScrollToIndexAction { index, animated in
                    guard data.indices.contains(index) else { return }

                    let target = data[index][keyPath: id]
                    if animated {
                        withAnimation {
                            scrollProxy.scrollTo(target, anchor: .center)
                        }
                    } else {
                        scrollProxy.scrollTo(target, anchor: .center)
                    }
                }
                collectionProxy?.setScrollToIDAction { target, animated in
                    if animated {
                        withAnimation {
                            scrollProxy.scrollTo(target, anchor: .center)
                        }
                    } else {
                        scrollProxy.scrollTo(target, anchor: .center)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func pageButton(
        systemImage: String,
        isAvailable: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let isVisible = isHovering && isAvailable

        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 28, height: 28)
                .background(.regularMaterial, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.25), radius: 4, y: 1)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
    }

    /// The width of the laid out content, derived instead of measured so that
    /// the trailing page button is correct before the first scroll event.
    private var contentWidth: CGFloat {
        let rows = max(gridItems.count, 1)
        let columns = (data.count + rows - 1) / rows

        guard columns > 0 else { return 0 }

        return horizontalInsets.leading
            + horizontalInsets.trailing
            + columnTrailingInset
            + CGFloat(columns) * (itemWidth + itemSpacingValue)
            - itemSpacingValue
    }

    private func updatePaging(offset: CGFloat, viewportWidth: CGFloat) {
        metrics.offset = offset
        metrics.viewportWidth = viewportWidth

        let maxOffset = max(contentWidth - viewportWidth, 0)
        let backward = viewportWidth > 0 && offset > 1
        let forward = viewportWidth > 0 && offset < maxOffset - 1

        guard backward != canPageBackward || forward != canPageForward else { return }

        withAnimation(.easeInOut(duration: 0.15)) {
            canPageBackward = backward
            canPageForward = forward
        }
    }

    private func page(_ direction: CollectionHStackPageDirection, scrollProxy: ScrollViewProxy) {
        let viewportWidth = metrics.viewportWidth
        let columnStride = itemWidth + itemSpacingValue

        guard viewportWidth > 0, columnStride > 0, !data.isEmpty else { return }

        let rows = max(gridItems.count, 1)
        let currentColumn = Int(((metrics.offset - horizontalInsets.leading) / columnStride).rounded())
        let visibleWidth = max(viewportWidth - horizontalInsets.leading - horizontalInsets.trailing, columnStride)
        let columnsPerPage = max(Int((visibleWidth + itemSpacingValue) / columnStride), 1)
        let lastColumn = max((data.count + rows - 1) / rows - 1, 0)

        let targetColumn = min(
            max(currentColumn + (direction == .forward ? columnsPerPage : -columnsPerPage), 0),
            lastColumn
        )

        // `scrollTo` aligns the same relative point of the item and of the
        // viewport, so a small anchor offset lands the target column at the
        // row's leading inset instead of flush against the window edge.
        let anchorX = min(max(horizontalInsets.leading / max(viewportWidth - itemWidth, 1), 0), 1)

        withAnimation(.easeInOut(duration: 0.25)) {
            if targetColumn == 0 {
                scrollProxy.scrollTo(CollectionHStackMarker.leading, anchor: .leading)
            } else {
                let index = data.startIndex + min(targetColumn * rows, data.count - 1)

                guard data.indices.contains(index) else { return }

                scrollProxy.scrollTo(data[index][keyPath: id], anchor: UnitPoint(x: anchorX, y: 0.5))
            }
        }
    }

    @ViewBuilder
    private func itemView(for element: Element) -> some View {
        viewProvider(element)
            .frame(width: itemWidth, alignment: .topLeading)
    }

    private var itemWidth: CGFloat {
        switch layout {
        case let .grid(columns, _, _):
            let columns = max(columns, 1)
            if columns <= 1.5 {
                return 300
            } else if columns <= 2 {
                return 260
            } else {
                return 200
            }
        case let .minimumWidth(columnWidth, _):
            return max(columnWidth, 1)
        case .selfSizingSameSize, .selfSizingVariadicWidth:
            return 200
        }
    }

    private var gridItems: [GridItem] {
        let rowCount: Int = switch layout {
        case let .grid(_, rows, _), let .minimumWidth(_, rows), let .selfSizingSameSize(rows), let .selfSizingVariadicWidth(rows):
            rows
        }
        return Array(
            repeating: GridItem(.flexible(), spacing: itemSpacingValue),
            count: max(rowCount, 1)
        )
    }

    private var columnTrailingInset: CGFloat {
        guard case let .grid(_, _, inset) = layout else { return 0 }
        return inset
    }

    func clipsToBounds(_ value: Bool) -> Self {
        self
    }

    func insets(_ insets: EdgeInsets) -> Self {
        var copy = self
        copy.horizontalInsets = insets
        return copy
    }

    func insets(horizontal: CGFloat = 0, vertical: CGFloat = 0) -> Self {
        insets(.init(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal))
    }

    func itemSpacing(_ spacing: CGFloat) -> Self {
        var copy = self
        copy.itemSpacingValue = spacing
        return copy
    }

    func proxy(_ proxy: CollectionHStackProxy) -> Self {
        var copy = self
        copy.collectionProxy = proxy
        return copy
    }

    func scrollBehavior(_ behavior: CollectionHStackScrollBehavior) -> Self {
        self
    }
}

extension CollectionHStack where Element: Identifiable, ID == Element.ID {

    init(
        uniqueElements: Data,
        minWidth: CGFloat,
        rows: Int = 1,
        @ViewBuilder content: @escaping (Element) -> Content
    ) {
        self.init(id: \.id, data: uniqueElements, layout: .minimumWidth(columnWidth: minWidth, rows: rows), viewProvider: content)
    }

    init(
        uniqueElements: Data,
        rows: Int = 1,
        variadicWidths: Bool = false,
        @ViewBuilder content: @escaping (Element) -> Content
    ) {
        self.init(
            id: \.id,
            data: uniqueElements,
            layout: variadicWidths ? .selfSizingVariadicWidth(rows: rows) : .selfSizingSameSize(rows: rows),
            viewProvider: content
        )
    }
}

#endif
