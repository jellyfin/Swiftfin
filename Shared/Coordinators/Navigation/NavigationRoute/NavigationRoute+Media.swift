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
import Transmission

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
            VideoPlayerViewShim(manager: manager)
        }
    }
}

// TODO: temporary shims for navigation work until video player refactor

struct VideoPlayerViewShim: View {

    @State
    private var safeAreaInsets: EdgeInsets = .init()

    let manager: MediaPlayerManager

    var body: some View {
        #if os(iOS)

        Group {
            if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                VideoPlayer(manager: manager)
                    .environment(\.safeAreaInsets, safeAreaInsets)
            } else {
                NativeVideoPlayer(manager: manager)
            }
        }
        .colorScheme(.dark) // use over `preferredColorScheme(.dark)` to not have destination change
        .supportedOrientations(.allButUpsideDown)
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden()
        .onSizeChanged { _, safeArea in
            self.safeAreaInsets = safeArea.max(EdgeInsets.edgePadding)
        }

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
