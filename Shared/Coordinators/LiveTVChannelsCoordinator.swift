//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
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
    var videoPlayer = makeVideoPlayer
    #endif

    #if os(tvOS)
    func makeVideoPlayer(manager: VideoPlayerManager) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        BasicNavigationViewCoordinator {
            Group {
                if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                    VideoPlayer(manager: manager)
                        .overlay {
                            VideoPlayer.Overlay()
                        }
                } else {
                    NativeVideoPlayer(manager: manager)
                }
            }
        }
        .inNavigationViewCoordinator()
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        LiveTVChannelsView()
    }
}
