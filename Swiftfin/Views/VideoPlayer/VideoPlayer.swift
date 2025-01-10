//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import Stinsen
import SwiftUI
import VLCUI

// TODO: move audio/subtitle offset to manager?

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
    private var audioOffset: TimeInterval = 0
    @State
    private var isAspectFilled: Bool = false
    @State
    private var isGestureLocked: Bool = false
    @State
    private var isScrubbing: Bool = false
    @State
    private var safeAreaInsets: EdgeInsets = .zero
    @State
    private var scrubbedSeconds: TimeInterval = 0
    @State
    private var subtitleOffset: TimeInterval = 0

    @StateObject
    private var manager: MediaPlayerManager
    @StateObject
    private var vlcUIProxy: VLCVideoPlayer.Proxy

    // MARK: init

    init(manager: MediaPlayerManager) {

        let videoPlayerProxy = VLCVideoPlayerProxy()
        let vlcUIProxy = VLCVideoPlayer.Proxy()

        videoPlayerProxy.vlcUIProxy = vlcUIProxy
        manager.proxy = videoPlayerProxy

        manager.listeners.append(NowPlayableListener(manager: manager))

        self._manager = StateObject(wrappedValue: manager)
        self._vlcUIProxy = StateObject(wrappedValue: vlcUIProxy)
    }

    // MARK: playerView

    @ViewBuilder
    private var playerView: some View {
        ZStack {

            Color.black

            if let playbackitem = manager.playbackItem {
                VLCVideoPlayer(configuration: playbackitem.vlcConfiguration)
                    .proxy(vlcUIProxy)
                    .onSecondsUpdated { newSeconds, _ in

                        if !isScrubbing {
                            scrubbedSeconds = newSeconds
                        }

                        // TODO: fix menu pulsing issue
                        manager.set(seconds: newSeconds)
                    }
                    .onStateUpdated { state, _ in

                        switch state {
                        case .buffering, .esAdded, .opening: ()
//                            if manager.playbackStatus != .buffering {
//                                manager.playbackStatus = .buffering
//                            }
                        case .ended, .stopped:
                            isScrubbing = false
                            manager.send(.ended)
                        case .error:
                            // TODO: localize
                            isScrubbing = false
                            manager.send(.error(.init("Unable to perform playback")))
                        case .playing:
                            manager.set(playbackRequestStatus: .playing)
                        case .paused:
                            manager.set(playbackRequestStatus: .paused)
                        }
                    }
            }

            Overlay()
                .environment(\.audioOffset, $audioOffset)
                .environment(\.isAspectFilled, $isAspectFilled)
                .environment(\.isGestureLocked, $isGestureLocked)
                .environment(\.isScrubbing, $isScrubbing)
                .environment(\.safeAreaInsets, safeAreaInsets)
                .environment(\.scrubbedSeconds, $scrubbedSeconds)
                .environmentObject(manager)
        }
    }

    // MARK: body

    var body: some View {
        playerView
            .ignoresSafeArea()
            .navigationBarHidden()
            .statusBarHidden()
            .trackingSize(.constant(.zero), $safeAreaInsets)
            .onChange(of: audioOffset) { newValue in
                vlcUIProxy.setAudioDelay(.seconds(newValue))
            }
            .onChange(of: isAspectFilled) { newValue in
                UIView.animate(withDuration: 0.2) {
                    vlcUIProxy.aspectFill(newValue ? 1 : 0)
                }
            }
            .onChange(of: isScrubbing) { isScrubbing in
                guard !isScrubbing else { return }

                manager.proxy?.setTime(scrubbedSeconds)
                manager.set(seconds: scrubbedSeconds)
            }
            .onChange(of: subtitleColor) { newValue in
                vlcUIProxy.setSubtitleColor(.absolute(newValue.uiColor))
            }
            .onChange(of: subtitleFontName) { newValue in
                vlcUIProxy.setSubtitleFont(newValue)
            }
            .onChange(of: subtitleOffset) { newValue in
                vlcUIProxy.setSubtitleDelay(.seconds(newValue))
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

                    scrubbedSeconds = seconds
                    vlcUIProxy.playNewMedia(item.vlcConfiguration)
                }
            }
    }
}
