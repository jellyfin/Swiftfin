//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
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

    @MainActor
    static func videoPlayer(
        item: BaseItemDto,
        mediaSource: MediaSourceInfo? = nil,
        queue: (any MediaPlayerQueue)? = nil
    ) -> NavigationRoute {
        let provider = MediaPlayerItemProvider(item: item) { item in
            try await MediaPlayerItem.build(for: item, mediaSource: mediaSource)
        }
        return Self.videoPlayer(provider: provider, queue: queue)
    }

    @MainActor
    static func videoPlayer(
        provider: MediaPlayerItemProvider,
        queue: (any MediaPlayerQueue)? = nil
    ) -> NavigationRoute {
        let manager = MediaPlayerManager(
            item: provider.item,
            queue: queue,
            mediaPlayerItemProvider: provider.function
        )

        return Self.videoPlayer(manager: manager)
    }

    @MainActor
    static func videoPlayer(manager: MediaPlayerManager) -> NavigationRoute {

        Container.shared.mediaPlayerManager.register {
            manager
        }

        Container.shared.mediaPlayerManagerPublisher()
            .send(manager)

        return NavigationRoute(
            id: "videoPlayer",
            style: .fullscreen
        ) {
            VideoPlayerViewShim(manager: manager)
        }
    }
}

// TODO: shim until native vs swiftfin player is replace with vlc vs av layers
//       - when removed, ensure same behavior with safe area
//       - may just need to make a VC wrapper to capture them

struct VideoPlayerViewShim: View {

    @State
    private var safeAreaInsets: EdgeInsets = .init()

    let manager: MediaPlayerManager

    var body: some View {
        Group {
            if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                VideoPlayer()
            } else {
                NativeVideoPlayer()
            }
        }
        .colorScheme(.dark) // use over `preferredColorScheme(.dark)` to not have destination change
        .environment(\.safeAreaInsets, safeAreaInsets)
        .supportedOrientations(.allButUpsideDown)
        .ignoresSafeArea()
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .onSizeChanged { _, safeArea in
            self.safeAreaInsets = safeArea.max(EdgeInsets.edgePadding)
        }
    }
}
