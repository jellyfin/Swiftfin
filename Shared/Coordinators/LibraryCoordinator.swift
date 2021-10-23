//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

typealias LibraryCoordinatorParams = (viewModel: LibraryViewModel, title: String)

final class LibraryCoordinator: NavigationCoordinatable {
    
    let stack = NavigationStack(initial: \LibraryCoordinator.start)

    @Root var start = makeStart
    @Route(.push) var search = makeSearch
    @Route(.modal) var filter = makeFilter
    @Route(.push) var item = makeItem
    @Route(.modal) var modalItem = makeModalItem

    let viewModel: LibraryViewModel
    let title: String

    init(viewModel: LibraryViewModel, title: String) {
        self.viewModel = viewModel
        self.title = title
    }

    @ViewBuilder func makeStart() -> some View {
        LibraryView(viewModel: self.viewModel, title: title)
    }

    func makeSearch(viewModel: LibrarySearchViewModel) -> SearchCoordinator {
        SearchCoordinator(viewModel: viewModel)
    }

    func makeFilter(params: FilterCoordinatorParams) -> NavigationViewCoordinator<FilterCoordinator> {
        NavigationViewCoordinator(FilterCoordinator(filters: params.filters,
                                                    enabledFilterType: params.enabledFilterType,
                                                    parentId: params.parentId))
    }

    func makeItem(item: BaseItemDto) -> ItemCoordinator {
        ItemCoordinator(item: item)
    }
    
    func makeModalItem(item: BaseItemDto) -> NavigationViewCoordinator<ItemCoordinator> {
        return NavigationViewCoordinator(ItemCoordinator(item: item))
    }
}
