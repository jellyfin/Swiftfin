//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import JellyfinAPI
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct GuideLibraryView<Library: PagingLibrary>: View where Library.Element: LibraryElement {

    @ObservedObject
    var viewModel: PagingLibraryViewModel<Library>

    @StateObject
    private var guideViewModel = GuideViewModel()

    let gridProxy: CollectionVGridProxy
    let libraryStyle: LibraryStyle

    private var channels: [BaseItemDto] {
        viewModel.displayedElements.compactMap { $0 as? BaseItemDto }
    }

    var body: some View {
        VStack(spacing: 0) {
            GuideTimeRuler(
                scrollProxy: guideViewModel.scrollProxy,
                startDate: guideViewModel.startDate,
                now: guideViewModel.now,
                layout: .current
            )

            Divider()

            CollectionVGrid(
                uniqueElements: channels,
                layout: .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
            ) { channel in
                channel.makeBody(libraryStyle: libraryStyle)
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                if viewModel.isSearchActive {
                    viewModel.getNextSearchPage()
                } else {
                    viewModel.getNextPage()
                }
            }
            .proxy(gridProxy)
            .scrollIndicators(.hidden)
            .environmentObject(guideViewModel)
            #if os(tvOS)
                .introspect(.scrollView, on: .tvOS(.v15...)) { scrollView in
                    scrollView.contentInsetAdjustmentBehavior = .never
                }
            #endif
        }
        #if os(tvOS)
        .padding(.leading, EdgeInsets.edgePadding * 2)
        .ignoresSafeArea(edges: .leading)
        #endif
    }
}
