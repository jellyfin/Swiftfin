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

final class LiveTVProgramsCoordinator: NavigationCoordinatable {

	let stack = NavigationStack(initial: \LiveTVProgramsCoordinator.start)

	@Root
	var start = makeStart
	@Route(.fullScreen)
	var videoPlayer = makeVideoPlayer

	func makeVideoPlayer(viewModel: VideoPlayerViewModel) -> NavigationViewCoordinator<LiveTVVideoPlayerCoordinator> {
		NavigationViewCoordinator(LiveTVVideoPlayerCoordinator(viewModel: viewModel))
	}

	@ViewBuilder
	func makeStart() -> some View {
		LiveTVProgramsView()
	}
}
