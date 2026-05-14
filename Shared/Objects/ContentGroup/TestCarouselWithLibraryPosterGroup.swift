//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import SwiftUI

struct TestCarouselWithLibraryPosterGroup: ContentGroup {

    let id: String = "test"
    let displayTitle: String = ""
    let filters: ItemFilterCollection
    let viewModel: PagingLibraryViewModel<ItemLibrary>

    init(filters: ItemFilterCollection) {
        self.filters = filters
        self.viewModel = PagingLibraryViewModel(
            library: ItemLibrary(
                parent: .init(),
                filters: filters
            )
        )
    }

    func body(with viewModel: PagingLibraryViewModel<ItemLibrary>) -> some View {
        PagingCarouselPosterHStack(
            library: viewModel
        )
    }
}

struct PagingCarouselPosterHStack<P: PagingLibrary>: View where P.Element: Poster {

    @Router
    private var router

    @State
    private var currentIndex = 0
    @State
    private var isAutoScrolling = false

    @StateObject
    private var collectionHStackProxy = CollectionHStackProxy()

    @ObservedObject
    private var viewModel: PagingLibraryViewModel<P>

    @StateObject
    private var scrollTimer = PokeIntervalTimer(defaultInterval: 2)

    private var pageCount: Int {
        min(20, viewModel.elements.count)
    }

    private var currentItem: P.Element? {
        viewModel.elements[safe: currentIndex]
    }

    init(library: PagingLibraryViewModel<P>) {
        _viewModel = ObservedObject(wrappedValue: library)
    }

    var body: some View {
        VStack {
            carouselView

            if pageCount > 1 {
                CarouselPageIndicator(
                    numberOfPages: pageCount,
                    currentPage: currentIndex,
                    maxDotsShown: 5,
                    onSelect: { index in
                        scrollTimer.stop()
                        scrollTo(index: index, animated: true)
                    }
                )
            }
        }
        .onReceive(scrollTimer) { _ in
            advancePage()
        }
        .onFirstAppear {
            restartAutoScroll()
        }
        .backport
        .onChange(of: viewModel.elements.count) { _, _ in
            clampCurrentIndex()
        }
    }

    @ViewBuilder
    private var carouselView: some View {
        CollectionHStack(
            uniqueElements: viewModel.elements,
            layout: .grid(columns: 1, rows: 1, columnTrailingInset: 0)
        ) { item in
            WithNamespace { namespace in
                Button {
                    if let item = item as? BaseItemDto {
                        scrollTimer.stop()
                        router.route(to: .item(item: item), in: namespace)
                    }
                } label: {
                    VStack(alignment: .leading) {
                        PosterImage(
                            item: item,
                            type: .landscape
                        )
                        .withViewContext(.isThumb)
                        .backport
                        .matchedTransitionSource(id: "item", in: namespace)

                        Text(item.displayTitle)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(.primary, .secondary)
            }
        }
        .proxy(collectionHStackProxy)
        .dataPrefix(20)
        .insets(horizontal: EdgeInsets.edgePadding)
        .itemSpacing(EdgeInsets.edgePadding / 2)
        .scrollBehavior(.columnPaging)
        ._didScrollToElements { items in
            currentIndex = items.map(\.indexPath.row).min() ?? 0
            if !isAutoScrolling {
                scrollTimer.stop()
            }
            isAutoScrolling = false
        }
        ._didEndDecelerating {
            restartAutoScroll()
        }
    }

    private func clampCurrentIndex() {
        guard pageCount > 0 else {
            currentIndex = 0
            return
        }
        currentIndex = min(currentIndex, pageCount - 1)
    }

    private func advancePage() {
        guard pageCount > 1 else { return }
        let nextIndex = (currentIndex + 1) % pageCount
        scrollTo(index: nextIndex, animated: true)
    }

    private func scrollTo(index: Int, animated: Bool) {
        guard viewModel.elements.indices.contains(index) else { return }
        isAutoScrolling = true

        if animated {
            withAnimation(.snappy) {
                collectionHStackProxy._scrollTo(index: index)
            }
        } else {
            collectionHStackProxy._scrollTo(index: index)
        }
    }

    private func restartAutoScroll() {
        scrollTimer.poke()
    }
}

struct CarouselPageIndicator: View {

    let numberOfPages: Int
    let currentPage: Int
    let maxDotsShown: Int
    let onSelect: (Int) -> Void

    private let dotSize: CGFloat = 8
    private let spacing: CGFloat = 8
    private let activeScale: CGFloat = 1.2
    private let fadeScale: CGFloat = 0.6

    private var visibleIndices: Range<Int> {
        let total = numberOfPages
        let window = maxDotsShown

        guard total > window else {
            return 0 ..< total
        }

        let halfWindow = window / 2
        let startLockout = halfWindow
        let endLockout = total - window + halfWindow

        if currentPage < startLockout {
            return 0 ..< window
        }
        if currentPage >= endLockout {
            return (total - window) ..< total
        }
        return (currentPage - halfWindow) ..< (currentPage - halfWindow + window)
    }

    private func scale(for index: Int) -> CGFloat {
        if index == currentPage {
            return activeScale
        }

        if numberOfPages > maxDotsShown {
            let window = visibleIndices
            if index == window.lowerBound, window.lowerBound > 0 {
                return fadeScale
            }
            if index == window.upperBound - 1, window.upperBound < numberOfPages {
                return fadeScale
            }
        }

        return 1.0
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(visibleIndices, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? HierarchicalShapeStyle.primary : HierarchicalShapeStyle.secondary)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(scale(for: index))
                    .animation(.linear(duration: 0.1), value: currentPage)
                    .onTapGesture {
                        onSelect(index)
                    }
            }
        }
    }
}
