//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import Stinsen
import SwiftUI
import VLCUI

struct VideoPlayer: View {

    @Default(.VideoPlayer.Subtitle.subtitleColor)
    private var subtitleColor
    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize

    @EnvironmentObject
    private var router: VideoPlayerCoordinator.Router

    @State
    private var audioOffset: Int = 0
    @State
    private var isAspectFilled: Bool = false
    @State
    private var isPresentingOverlay: Bool = true
    @State
    private var isScrubbing: Bool = false
    @State
    private var playbackSpeed: Double = 1
    @State
    private var subtitleOffset: Int = 0
    @State
    private var safeAreaInsets: EdgeInsets = .zero

    @StateObject
    private var scrubbedProgress: ProgressBox = .init()

    @StateObject
    private var manager: MediaPlayerManager
    @StateObject
    private var vlcUIProxy: VLCVideoPlayer.Proxy

    // MARK: playerView

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

            MainOverlay()
                .environment(\.isAspectFilled, $isAspectFilled)
                .environment(\.isPresentingOverlay, $isPresentingOverlay)
                .environment(\.isScrubbing, $isScrubbing)
                .environment(\.playbackSpeed, $playbackSpeed)
                .environment(\.safeAreaInsets, $safeAreaInsets)
                .environmentObject(manager)
                .environmentObject(scrubbedProgress)
                .environmentObject(vlcUIProxy)
        }
    }

    // MARK: body

    var body: some View {

        let _ = Self._printChanges()

        playerView
            .ignoresSafeArea()
            .navigationBarHidden()
            .statusBarHidden()
            .trackingSize(.constant(.zero), $safeAreaInsets)
            .onChange(of: audioOffset) { newValue in
                vlcUIProxy.setAudioDelay(.ticks(newValue))
            }
            .onChange(of: isAspectFilled) { newValue in
                UIView.animate(withDuration: 0.2) {
                    vlcUIProxy.aspectFill(newValue ? 1 : 0)
                }
            }
            .onChange(of: isScrubbing) { isScrubbing in
                guard !isScrubbing else { return }

                vlcUIProxy.setTime(.seconds(scrubbedProgress.seconds))
            }
            .onChange(of: scrubbedProgress.progress) { progress in
                scrubbedProgress.seconds = Int(progress * CGFloat(manager.item.runTimeSeconds))
            }
            .onChange(of: subtitleColor) { newValue in
                vlcUIProxy.setSubtitleColor(.absolute(newValue.uiColor))
            }
            .onChange(of: subtitleFontName) { newValue in
                vlcUIProxy.setSubtitleFont(newValue)
            }
            .onChange(of: subtitleOffset) { newValue in
                vlcUIProxy.setSubtitleDelay(.ticks(newValue))
            }
            .onChange(of: subtitleSize) { newValue in
                vlcUIProxy.setSubtitleSize(.absolute(24 - newValue))
            }
            .onReceive(manager.events) { @MainActor event in
                switch event {
                case .playbackStopped:
                    vlcUIProxy.stop()
                    router.dismissCoordinator()
                case let .playNew(playbackItem: item):
                    isAspectFilled = false
                    audioOffset = 0
                    subtitleOffset = 0

                    let seconds = item.vlcConfiguration
                        .startTime
                        .asSeconds

                    let progress = CGFloat(seconds) / CGFloat(item.baseItem.runTimeSeconds)

                    scrubbedProgress.progress = progress
                    scrubbedProgress.seconds = seconds

                    vlcUIProxy.playNewMedia(item.vlcConfiguration)
                }
            }
    }
}

// MARK: init

extension VideoPlayer {

    // TODO: take in manager instead

    init(item: BaseItemDto, mediaSource: MediaSourceInfo) {

        let manager = MediaPlayerManager(item: item, mediaSource: mediaSource)
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

        let manager = MediaPlayerManager(playbackItem: item)
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

// struct VideoPlayer_Previews: PreviewProvider {
//    static var previews: some View {
//        VideoPlayer(
//            item: .init(
//                baseItem: .init(name: "Top Gun Maverick", runTimeTicks: 10_000_000_000),
//                mediaSource: .init(),
//                playSessionID: "",
//                url: URL(string: "/")!
//            )
//        )
//        .previewInterfaceOrientation(.landscapeLeft)
//        .preferredColorScheme(.dark)
//    }
// }
