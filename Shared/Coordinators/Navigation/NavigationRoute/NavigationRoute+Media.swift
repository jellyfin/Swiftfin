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

    static func liveVideoPlayer(manager: LiveVideoPlayerManager) -> NavigationRoute {
        NavigationRoute(
            id: "liveVideoPlayer",
            style: .fullscreen
        ) {
            LiveVideoPlayerViewShim(videoPlayerManager: manager)
        }
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

    static func videoPlayer(manager: VideoPlayerManager) -> NavigationRoute {
        NavigationRoute(
            id: "videoPlayer",
            style: .fullscreen
        ) {
            VideoPlayerViewShim(videoPlayerManager: manager)
        }
    }
}

// TODO: temporary shims for navigation work until video player refactor

struct VideoPlayerViewShim: View {

    @StateObject
    var videoPlayerManager: VideoPlayerManager

    var body: some View {
        #if os(iOS)

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
        .persistentSystemOverlays(.hidden)

        #else
        if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
            PreferencesView {
                VideoPlayer(manager: self.videoPlayerManager)
            }
            .ignoresSafeArea()
        } else {
            NativeVideoPlayer(manager: self.videoPlayerManager)
        }
        #endif
    }
}

struct LiveVideoPlayerViewShim: View {

    @StateObject
    var videoPlayerManager: LiveVideoPlayerManager

    var body: some View {
        #if os(iOS)

        PreferencesView {
            Group {
                if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                    LiveVideoPlayer(manager: self.videoPlayerManager)
                } else {
                    LiveNativeVideoPlayer(manager: self.videoPlayerManager)
                }
            }
            .preferredColorScheme(.dark)
            .supportedOrientations(UIDevice.isPhone ? .landscape : .allButUpsideDown)
        }
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)

        #else

        PreferencesView {
            if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                LiveVideoPlayer(manager: self.videoPlayerManager)
            } else {
                LiveNativeVideoPlayer(manager: self.videoPlayerManager)
            }
        }
        .ignoresSafeArea()

        #endif
    }
}
