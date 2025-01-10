//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import PreferencesView
import Stinsen
import SwiftUI

// TODO: should take a manager instead?
final class VideoPlayerCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \VideoPlayerCoordinator.start)

    @Root
    var start = makeStart

    private var manager: MediaPlayerManager

    init(manager: MediaPlayerManager) {
        self.manager = manager
    }

    // TODO: removed after iOS 15 support removed

    #if os(iOS)
    @ViewBuilder
    private var versionedView: some View {
        if #available(iOS 16, *) {
            PreferencesView {
                ZStack {
                    if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                        VideoPlayer(manager: self.manager)
                    } else {
                        NativeVideoPlayer(manager: self.manager)
                    }
                }
                .preferredColorScheme(.dark)
                .supportedOrientations(UIDevice.isPhone ? .landscape : .allButUpsideDown)
            }
        } else {
            Group {
                if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
//                    VideoPlayer(manager: self.videoPlayerManager)
                    Color.red
                } else {
                    Color.red
//                    NativeVideoPlayer(manager: self.videoPlayerManager)
                }
            }
            .preferredColorScheme(.dark)
//            .supportedOrientations(UIDevice.isPhone ? .landscape : .allButUpsideDown)
        }
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        #if os(iOS)

        // Some settings have to apply to the root PreferencesView and this
        // one - separately.
        // It is assumed that because Stinsen adds a lot of views that the
        // PreferencesView isn't in the right place in the VC chain so that
        // it can apply the settings, even SwiftUI settings.
        versionedView
            .preferredColorScheme(.dark)
            .ignoresSafeArea()
            .backport
            .persistentSystemOverlays(.hidden)

        #else

        ZStack {
            if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                VideoPlayer(manager: self.manager)
            } else {
//                NativeVideoPlayer(manager: self.manager)
                Color.red
            }
        }
        #endif
    }
}
