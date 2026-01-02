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

struct TestCarouselWithLibraryPosterGroup: _ContentGroup {

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
    private var currentIndex: Int = 0
    @State
    private var didSkipInitialStop = false

    @StateObject
    private var collectionHStackProxy = CollectionHStackProxy()

    @StateObject
    private var viewModel: PagingLibraryViewModel<P>

    @StateObject
    private var scrollTimer = PokeIntervalTimer(defaultInterval: 2)

    private var currentItem: P.Element? {
        guard viewModel.elements.indices.contains(currentIndex) else { return nil }
        return viewModel.elements[currentIndex]
    }

    init(library: PagingLibraryViewModel<P>) {
        _viewModel = StateObject(wrappedValue: library)
    }

    var body: some View {
        VStack {
            CollectionHStack(
                uniqueElements: viewModel.elements,
                layout: .grid(columns: 1, rows: 1, columnTrailingInset: 0)
            ) { item in
                PosterButton(
                    item: item,
                    type: .landscape
                ) { namespace in
                    if let item = item as? BaseItemDto {
                        scrollTimer.stop()
                        router.route(to: .item(item: item), in: namespace)
                    }
                }
            }
            .proxy(collectionHStackProxy)
            .clipsToBounds(false)
            .dataPrefix(20)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollBehavior(.columnPaging)
            ._didScrollToElements { items in
                if !didSkipInitialStop {
                    didSkipInitialStop = true
                } else {
                    scrollTimer.stop()
                }
                currentIndex = items.map(\.indexPath.row).min() ?? 0
            }
            ._didEndDecelerating {
                scrollTimer.poke()
            }

            VStack(alignment: .leading) {
                Text(currentItem?.displayTitle ?? .emptyDash)
                    .font(.headline)
                    .lineLimit(1)
            }
            .edgePadding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)

            DottedPageIndicator(
                numberOfPages: min(20, viewModel.elements.count),
                currentPage: $currentIndex,
                maxDotsShown: 5
            )
        }
        .onReceive(scrollTimer) { _ in
            if currentIndex < min(19, viewModel.elements.count - 1) {
                withAnimation(.bouncy) {
//                    collectionHStackProxy.scrollTo(index: currentIndex + 1, animated: false)
                    collectionHStackProxy._scrollTo(index: currentIndex + 1)
                }
            } else {
                collectionHStackProxy.scrollTo(index: 0, animated: true)
            }
        }
        .onFirstAppear {
            scrollTimer.poke()
        }
    }
}

struct DottedPageIndicator: View {
    // 1. Total number of pages
    let numberOfPages: Int

    // 2. Binding to the current page index
    @Binding
    var currentPage: Int

    // 3. Maximum number of dots visible at any time (New Property)
    let maxDotsShown: Int

    // Configurable visual constants
    let dotSize: CGFloat = 8
    let spacing: CGFloat = 8

    // Scale for the active dot
    private let activeScale: CGFloat = 1.2
    // Scale for the fading dots at the window edge
    private let fadeScale: CGFloat = 0.6

    // MARK: - Windowed Logic

    /**
     Calculates the range of page indices that should be visible in the indicator.
     This creates the "window" effect when numberOfPages > maxDotsShown.
     */
    private var visibleIndices: Range<Int> {
        let total = numberOfPages
        let window = maxDotsShown

        if total <= window {
            return 0 ..< total
        }

        // halfWindow defines the centering point
        let halfWindow = window / 2

        // Define the lockout zones where the window should be fixed
        let startLockout = halfWindow
        let endLockout = total - window + halfWindow

        if currentPage < startLockout {
            // Fixed start window: [0] to [window - 1]
            return 0 ..< window
        } else if currentPage >= endLockout {
            // Fixed end window: [total - window] to [total - 1]
            return (total - window) ..< total
        } else {
            // Centered window: [currentPage - halfWindow] to [currentPage + halfWindow (plus adjustment for even numbers)]
            return (currentPage - halfWindow) ..< (currentPage - halfWindow + window)
        }
    }

    /**
     Calculates the scale for a dot at a specific index, applying the fading effect
     for dots positioned at the visible edges of the indicator window.
     */
    private func scale(for index: Int) -> CGFloat {
        // 1. Active Page
        if index == currentPage {
            return activeScale
        }

        // 2. Windowed Fading Effect (only if trimming dots)
        if numberOfPages > maxDotsShown {
            let window = visibleIndices

            // Check for fading at the start of the window, only if we are past the first page
            if index == window.lowerBound && window.lowerBound > 0 {
                return fadeScale
            }

            // Check for fading at the end of the window, only if we are not at the last page
            if index == window.upperBound - 1 && window.upperBound < numberOfPages {
                return fadeScale
            }
        }

        // 3. Default inactive scale
        return 1.0
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(visibleIndices, id: \.self) { index in
                Circle()
                    // Set fill color based on whether the index matches the current page
                        .fill(index == currentPage ? HierarchicalShapeStyle.primary : HierarchicalShapeStyle.secondary)
                        // Set the base size
                        .frame(width: dotSize, height: dotSize)
                        // Apply the calculated scale based on active state or window edge
                        .scaleEffect(scale(for: index))
                        // Add a subtle animation for smooth transitions between pages and scaling
//                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentPage)
                        .animation(.linear(duration: 0.1), value: currentPage)
                        // Allow the user to tap a dot to jump to that page
                        .onTapGesture {
                            withAnimation {
                                currentPage = index
                            }
                        }
            }
        }
    }
}
