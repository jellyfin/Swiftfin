//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import MediaPlayer
import Stinsen
import SwiftUI
import VLCUI

struct VideoPlayer: View {

    enum OverlayType {
//        case chapters
        case confirmClose
        case main
//        case smallMenu
    }

    @Environment(\.scenePhase)
    private var scenePhase

    @EnvironmentObject
    private var router: VideoPlayerCoordinator.Router

//    @ObservedObject
//    private var currentProgressHandler: MediaPlayerManager.CurrentProgressHandler
    @StateObject
    private var manager: MediaPlayerManager
    @StateObject
    private var scrubbedProgress: ProgressBox = .init()

    @State
    private var isPresentingOverlay: Bool = false
    @State
    private var isScrubbing: Bool = false

    @StateObject
    private var vlcUIProxy: VLCVideoPlayer.Proxy

    @ViewBuilder
    private var playerView: some View {
        ZStack {

            Color.black

            if let playbackitem = manager.playbackItem {
                VLCVideoPlayer(configuration: playbackitem.vlcConfiguration)
                    .proxy(vlcUIProxy)
                    .onTicksUpdated { ticks, _ in

                        guard manager.state != .initial || manager.state != .loadingItem else { return }

                        let newSeconds = ticks / 1000
                        let newProgress = CGFloat(newSeconds) / CGFloat(manager.item.runTimeSeconds)

                        if !isScrubbing {
                            scrubbedProgress.progress = newProgress
                        }

                        manager.send(.seek(seconds: newSeconds))
                    }
                    .onStateUpdated { state, _ in
                        switch state {
                        case .buffering, .esAdded, .opening:
                            manager.send(.buffer)
                        case .ended, .stopped:
                            isScrubbing = false
                            manager.send(.ended)
                        case .error:
                            // TODO: localize
                            isScrubbing = false
                            manager.send(.error(.init("Unable to perform playback")))
                        case .playing:
                            manager.send(.play)
                        case .paused:
                            manager.send(.pause)
                        }
                    }
            }

            Overlay()
//                .environment(\.isAspectFilled, $isAspectFilled)
                    .environment(\.isPresentingOverlay, $isPresentingOverlay)
                    .environment(\.isScrubbing, $isScrubbing)
//                .environment(\.playbackSpeed, $playbackSpeed)
                    .environmentObject(manager)
                    .environmentObject(scrubbedProgress)
                    .environmentObject(vlcUIProxy)
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        Text("Retrieving media information")
    }

    var body: some View {
        playerView
            .ignoresSafeArea()
//        .onChange(of: isScrubbing) { _, newValue in
//            guard !newValue else { return }
//            vlcUIProxy.setTime(.seconds(currentProgressHandler.scrubbedSeconds))
//        }
//        .onScenePhase(.active) {
//            if Defaults[.VideoPlayer.Transition.playOnActive] {
//                videoPlayerManager.proxy.play()
//            }
//        }
//        .onScenePhase(.background) {
//            if Defaults[.VideoPlayer.Transition.pauseOnBackground] {
//                videoPlayerManager.proxy.pause()
//            }
//        }
    }
}

extension VideoPlayer {

    init(item: BaseItemDto, mediaSource: MediaSourceInfo) {

        let manager = VideoPlayerManager(item: item, mediaSource: mediaSource)
        let videoPlayerProxy = VLCVideoPlayerProxy()
        let vlcUIProxy = VLCVideoPlayer.Proxy()

        videoPlayerProxy.vlcUIProxy = vlcUIProxy
        manager.proxy = videoPlayerProxy

        self.init(
            manager: manager,
            vlcUIProxy: vlcUIProxy
        )
    }

    init(item: MediaPlayerItem) {

        let manager = VideoPlayerManager(playbackItem: item)
        let videoPlayerProxy = VLCVideoPlayerProxy()
        let vlcUIProxy = VLCVideoPlayer.Proxy()

        videoPlayerProxy.vlcUIProxy = vlcUIProxy
        manager.proxy = videoPlayerProxy

        self.init(
            manager: manager,
            vlcUIProxy: vlcUIProxy
        )
    }
}
