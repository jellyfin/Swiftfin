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

final class LiveTVChannelsCoordinator: NavigationCoordinatable {
	let stack = NavigationStack(initial: \LiveTVChannelsCoordinator.start)

	@Root
	var start = makeStart
	@Route(.modal)
	var modalItem = makeModalItem
	@Route(.fullScreen)
	var videoPlayer = makeVideoPlayer

	func makeModalItem(item: BaseItemDto) -> NavigationViewCoordinator<ItemCoordinator> {
		NavigationViewCoordinator(ItemCoordinator(item: item))
	}
    
	func makeVideoPlayer(viewModel: VideoPlayerViewModel) -> NavigationViewCoordinator<LiveTVVideoPlayerCoordinator> {
		NavigationViewCoordinator(LiveTVVideoPlayerCoordinator(viewModel: viewModel))
	}

	@ViewBuilder
	func makeStart() -> some View {
		LiveTVChannelsView()
	}
}

final class EmptyViewCoordinator: NavigationCoordinatable {
	let stack = NavigationStack(initial: \EmptyViewCoordinator.start)

	@Root
	var start = makeStart

	@ViewBuilder
	func makeStart() -> some View {
		Text("Empty")
	}
}
