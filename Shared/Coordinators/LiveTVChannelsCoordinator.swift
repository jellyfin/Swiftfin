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

final class LiveTVChannelsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \LiveTVChannelsCoordinator.start)

    @Root
    var start = makeStart

    #if os(tvOS)
    @Route(.fullScreen)
    var liveVideoPlayer = makeLiveVideoPlayer
    #endif

    #if os(tvOS)
    func makeLiveVideoPlayer(manager: LiveVideoPlayerManager) -> NavigationViewCoordinator<LiveVideoPlayerCoordinator> {
        NavigationViewCoordinator(LiveVideoPlayerCoordinator(manager: manager))
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        LiveTVChannelsView()
    }
}
