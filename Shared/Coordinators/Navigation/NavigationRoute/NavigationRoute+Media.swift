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

    static var channels: NavigationRoute {
        NavigationRoute(
            id: "channels"
        ) {
            ChannelLibraryView()
        }
    }

    static var liveTV: NavigationRoute {
        NavigationRoute(
            id: "liveTV"
        ) {
            ProgramsView()
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

    static func mediaStreamInfo(mediaStream: MediaStream) -> NavigationRoute {
        NavigationRoute(id: "mediaStreamInfo") {
            MediaStreamInfoView(mediaStream: mediaStream)
        }
    }

    @MainActor
    static func videoPlayer(
        item: BaseItemDto,
        mediaSource: MediaSourceInfo? = nil,
        queue: (any MediaPlayerQueue)? = nil,
        startTimeTicks: Int? = nil
    ) -> NavigationRoute {
        // Hybrid engine selection happens HERE, at route time, because the player view fixes its proxy
        // (VLC vs AVPlayer) in its initializer — before the async build runs. We resolve the engine once
        // from the item's media streams and thread the SAME value to both the build (so the device
        // profile matches) and the view shim (so the proxy matches). See `VideoPlayerType.hybrid(for:)`.
        let playerType = VideoPlayerType.hybrid(for: mediaSource ?? item.mediaSources?.first)

        let provider = MediaPlayerItemProvider(item: item) { item in
            try await MediaPlayerItem.build(
                for: item,
                mediaSource: mediaSource,
                videoPlayerType: playerType,
                // `build` re-fetches the item via `getFullItem`, which replaces any resume position the
                // caller set on `item.userData`. SyncPlay needs the player to start at the GROUP's current
                // position (not this user's saved one), so we re-apply it here, AFTER the re-fetch.
                modifyItem: startTimeTicks.map { ticks in
                    { (built: inout BaseItemDto) in
                        if built.userData == nil {
                            built.userData = UserItemDataDto()
                        }
                        built.userData?.playbackPositionTicks = ticks
                    }
                }
            )
        }
        return Self.videoPlayer(provider: provider, queue: queue, playerType: playerType)
    }

    @MainActor
    static func videoPlayer(
        provider: MediaPlayerItemProvider,
        queue: (any MediaPlayerQueue)? = nil,
        playerType: VideoPlayerType = Defaults[.VideoPlayer.videoPlayerType]
    ) -> NavigationRoute {
        let manager = MediaPlayerManager(
            item: provider.item,
            queue: queue,
            mediaPlayerItemProvider: provider.function
        )

        return Self.videoPlayer(manager: manager, playerType: playerType)
    }

    @MainActor
    static func videoPlayer(
        manager: MediaPlayerManager,
        playerType: VideoPlayerType = Defaults[.VideoPlayer.videoPlayerType]
    ) -> NavigationRoute {

        Container.shared.mediaPlayerManager.register {
            manager
        }

        Container.shared.mediaPlayerManagerPublisher()
            .send(manager)

        return NavigationRoute(
            id: "videoPlayer",
            style: .fullscreen
        ) {
            VideoPlayerViewShim(manager: manager, videoPlayerType: playerType)
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

    /// The engine resolved for this item by `VideoPlayerType.hybrid(for:)` (native AVPlayer for HDR /
    /// Dolby Vision, VLC otherwise). Drives which proxy-backed view — and therefore which player — is
    /// presented, kept consistent with the device profile the item was built with.
    let videoPlayerType: VideoPlayerType

    var body: some View {
        Group {
            if videoPlayerType == .swiftfin {
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
