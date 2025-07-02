//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import PreferencesView
import SwiftUI

extension NavigationRoute {

    static let channels = NavigationRoute(
        id: "channels"
    ) {
        ChannelLibraryView()
    }

    static let liveTV = NavigationRoute(
        id: "liveTV"
    ) {
        ProgramsView()
    }

    static func mediaSourceInfo(source: MediaSourceInfo) -> NavigationRoute {
        NavigationRoute(
            id: "mediaSourceInfo",
            style: .sheet
        ) {
            MediaSourceInfoView(source: source)
        }
    }

    #if os(iOS)
    static func mediaStreamInfo(mediaStream: MediaStream) -> NavigationRoute {
        NavigationRoute(id: "mediaStreamInfo") {
            MediaStreamInfoView(mediaStream: mediaStream)
        }
    }
    #endif

    static func videoPlayer(manager: MediaPlayerManager) -> NavigationRoute {
        NavigationRoute(
            id: "videoPlayer",
            style: .fullscreen
        ) {
            VideoPlayerShim(manager: manager)
        }
    }
}

struct VideoPlayerShim: View {

    let manager: MediaPlayerManager

    var body: some View {
        PreferencesView {
            Group {
                if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                    VideoPlayer(manager: manager)
                } else {
                    NativeVideoPlayer(manager: manager)
                }
            }
            .preferredColorScheme(.dark)
            .supportedOrientations(UIDevice.isPhone ? .allButUpsideDown : .allButUpsideDown)
        }
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .supportedOrientations(UIDevice.isPhone ? .allButUpsideDown : .allButUpsideDown)
    }
}
