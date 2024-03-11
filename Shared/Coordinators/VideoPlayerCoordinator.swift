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
import PreferencesView
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

        // Some settings have to apply to the root PreferencesView and this
        // one - separately.
        // It is assumed that because Stinsen adds a lot of views that the
        // PreferencesView isn't in the right place in the VC chain so that
        // it can apply the settings, even SwiftUI settings.
        PreferencesView {
            Group {
                if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                    VideoPlayer(manager: self.videoPlayerManager)
                } else {
                    NativeVideoPlayer(manager: self.videoPlayerManager)
                }
            }
            .preferredColorScheme(.dark)
            .supportedOrientations(UIDevice.isPhone ? .landscape : .allButUpsideDown)
        }
        .ignoresSafeArea()
        .backport
        .persistentSystemOverlays(.hidden)
        .backport
        .defersSystemGestures(on: .all)

        #else
        if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
            PreferencesView {
                VideoPlayer(manager: self.videoPlayerManager)
            }
        } else {
            NativeVideoPlayer(manager: self.videoPlayerManager)
        }
        #endif
    }
}
