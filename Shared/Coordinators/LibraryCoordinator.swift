//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class LibraryCoordinator: NavigationCoordinatable {

	let stack = NavigationStack(initial: \LibraryCoordinator.start)

	@Root
	var start = makeStart
	@Route(.push)
	var search = makeSearch
	@Route(.modal)
	var filter = makeFilter
	@Route(.push)
	var item = makeItem
	@Route(.modal)
	var modalItem = makeModalItem

	let viewModel: LibraryViewModel

	init(viewModel: LibraryViewModel) {
		self.viewModel = viewModel
	}

	@ViewBuilder
	func makeStart() -> some View {
		LibraryView(viewModel: self.viewModel)
	}

	func makeSearch(viewModel: LibrarySearchViewModel) -> SearchCoordinator {
		SearchCoordinator(viewModel: viewModel)
	}

	func makeFilter(params: FilterCoordinatorParams) -> NavigationViewCoordinator<FilterCoordinator> {
        NavigationViewCoordinator(FilterCoordinator(libraryItem: viewModel.libraryItem,
                                                    filters: params.filters,
                                                    enabledFilterType: params.enabledFilterType))
	}

	func makeItem(item: BaseItemDto) -> ItemCoordinator {
		ItemCoordinator(item: item)
	}

	func makeModalItem(item: BaseItemDto) -> NavigationViewCoordinator<ItemCoordinator> {
		NavigationViewCoordinator(ItemCoordinator(item: item))
	}
}
