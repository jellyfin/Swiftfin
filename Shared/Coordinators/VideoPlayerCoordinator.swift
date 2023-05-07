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

final class VideoPlayerCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \VideoPlayerCoordinator.start)

    @Root
    var start = makeStart

    let videoPlayerManager: VideoPlayerManager

    init(manager: VideoPlayerManager) {
        self.videoPlayerManager = manager
    }

    @ViewBuilder
    func makeStart() -> some View {
        #if os(iOS)

        PreferenceUIHostingControllerView {
            Group {
                if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                    VideoPlayer(manager: self.videoPlayerManager)
                } else {
                    NativeVideoPlayer(manager: self.videoPlayerManager)
                }
            }
            .overrideViewPreference(.dark)
        }
        .ignoresSafeArea()
        .hideSystemOverlays()
//        .onAppear {
//            AppDelegate.changeOrientation(.landscape)
//        }

        #else

        PreferenceUIHostingControllerView {
            Group {
                if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                    VideoPlayer(manager: self.videoPlayerManager)
                        .overlay {
                            VideoPlayer.Overlay()
                        }
                } else {
                    NativeVideoPlayer(manager: self.videoPlayerManager)
                }
            }
        }
        .ignoresSafeArea()

        #endif
    }
}
