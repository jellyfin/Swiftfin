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

final class ItemCoordinator: NavigationCoordinatable {

	let stack = NavigationStack(initial: \ItemCoordinator.start)

	@Root
	var start = makeStart
	@Route(.push)
	var item = makeItem
	@Route(.push)
	var library = makeLibrary
	@Route(.modal)
	var itemOverview = makeItemOverview
	@Route(.fullScreen)
	var videoPlayer = makeVideoPlayer

	let itemDto: BaseItemDto

	init(item: BaseItemDto) {
		self.itemDto = item
	}

	func makeLibrary(params: LibraryCoordinatorParams) -> LibraryCoordinator {
		LibraryCoordinator(viewModel: params.viewModel, title: params.title)
	}

	func makeItem(item: BaseItemDto) -> ItemCoordinator {
		ItemCoordinator(item: item)
	}

	func makeItemOverview(item: BaseItemDto) -> NavigationViewCoordinator<ItemOverviewCoordinator> {
		NavigationViewCoordinator(ItemOverviewCoordinator(item: itemDto))
	}

	func makeVideoPlayer(viewModel: VideoPlayerViewModel) -> NavigationViewCoordinator<VideoPlayerCoordinator> {
		NavigationViewCoordinator(VideoPlayerCoordinator(viewModel: viewModel))
	}

	@ViewBuilder
	func makeStart() -> some View {
		ItemNavigationView(item: itemDto)
	}
}
