//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Algorithms
import Defaults
import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class LiveTVProgramsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \LiveTVProgramsCoordinator.start)

    @Root
    var start = makeStart

    #if os(tvOS)
    @Route(.fullScreen)
    var videoPlayer = makeVideoPlayer
    #endif

    #if os(tvOS)
    func makeVideoPlayer(manager: LiveVideoPlayerManager) -> NavigationViewCoordinator<LiveVideoPlayerCoordinator> {
        NavigationViewCoordinator(LiveVideoPlayerCoordinator(manager: manager))
    }

    func makeStart() -> some View {
        let viewModel = LiveTVProgramsViewModel()
        return LiveTVProgramsView(viewModel: viewModel)
    }
    #endif

    func makeStart() -> some View {
        AssertionFailureView("Not implemented")
    }
}
