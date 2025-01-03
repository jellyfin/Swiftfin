//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Stinsen
import SwiftUI

final class PlaybackSettingsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \PlaybackSettingsCoordinator.start)

    @Root
    var start = makeStart
    @Route(.push)
    var videoPlayerSettings = makeVideoPlayerSettings

    #if os(iOS)
    @Route(.push)
    var mediaStreamInfo = makeMediaStreamInfo
    #endif

    func makeVideoPlayerSettings() -> VideoPlayerSettingsCoordinator {
        VideoPlayerSettingsCoordinator()
    }

    #if os(iOS)
    @ViewBuilder
    func makeMediaStreamInfo(mediaStream: MediaStream) -> some View {
        MediaStreamInfoView(mediaStream: mediaStream)
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        #if os(iOS)
        PlaybackSettingsView()
        #else
        EmptyView()
        #endif
    }
}
