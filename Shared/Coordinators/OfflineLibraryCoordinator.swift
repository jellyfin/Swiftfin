//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class OfflineLibraryCoordinator<Element: Poster>: NavigationCoordinatable {

    let stack = NavigationStack(initial: \OfflineLibraryCoordinator.start)

    @Root
    var start = makeStart

    #if os(tvOS)
    @Route(.modal)
    var item = makeItem
    @Route(.push)
    var library = makeLibrary
    #else
    @Route(.push)
    var item = makeItem
    @Route(.push)
    var library = makeLibrary
    @Route(.modal)
    var filter = makeFilter
    #endif

    private let viewModel: PagingLibraryViewModel<Element>
    private let offlineViewModel: OfflineViewModel

    init(viewModel: PagingLibraryViewModel<Element>, offlineViewModel: OfflineViewModel) {
        self.viewModel = viewModel
        self.offlineViewModel = offlineViewModel
    }

    @ViewBuilder
    func makeStart() -> some View {
        PagingLibraryView(viewModel: viewModel)
    }

    #if os(tvOS)
    func makeItem(item: BaseItemDto) -> NavigationViewCoordinator<ItemCoordinator> {
        NavigationViewCoordinator(ItemCoordinator(item: item))
    }

    func makeLibrary(viewModel: PagingLibraryViewModel<BaseItemDto>) -> NavigationViewCoordinator<LibraryCoordinator<BaseItemDto>> {
        NavigationViewCoordinator(LibraryCoordinator<BaseItemDto>(viewModel: viewModel))
    }
    #else
    func makeItem(item: BaseItemDto) -> OfflineItemCoordinator {
        OfflineItemCoordinator(item: item, viewModel: offlineViewModel)
    }

    func makeLibrary(viewModel: PagingLibraryViewModel<BaseItemDto>) -> LibraryCoordinator<BaseItemDto> {
        LibraryCoordinator<BaseItemDto>(viewModel: viewModel)
    }

    func makeFilter(parameters: FilterCoordinator.Parameters) -> NavigationViewCoordinator<FilterCoordinator> {
        NavigationViewCoordinator(FilterCoordinator(parameters: parameters))
    }
    #endif
}
