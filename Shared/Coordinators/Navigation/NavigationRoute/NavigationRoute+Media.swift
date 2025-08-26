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
            VideoPlayerViewShim(manager: manager)
        }
    }

    static func videoPlayer(item: BaseItemDto, mediaSource: MediaSourceInfo) -> NavigationRoute {
        let manager = MediaPlayerManager(item: item) { item in
            try await MediaPlayerItem.build(for: item, mediaSource: mediaSource)
        }

        return Self.videoPlayer(manager: manager)
    }
}

// TODO: shim until native vs swiftfin player is replace with vlc vs av layers

struct VideoPlayerViewShim: View {

    @State
    private var safeAreaInsets: EdgeInsets = .init()

    let manager: MediaPlayerManager

    var body: some View {
        Group {
            if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                VideoPlayer(manager: manager)
            } else {
                NativeVideoPlayer(manager: manager)
            }
        }
        .colorScheme(.dark) // use over `preferredColorScheme(.dark)` to not have destination change
        .environment(\.safeAreaInsets, safeAreaInsets)
        .supportedOrientations(.allButUpsideDown)
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden()
        .onSizeChanged { _, safeArea in
            self.safeAreaInsets = safeArea.max(EdgeInsets.edgePadding)
        }
    }
}
