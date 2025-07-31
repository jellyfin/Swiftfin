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
import VLCUI

// TODO: move audio/subtitle offset to manager?

struct VideoPlayer: View {

    @Default(.VideoPlayer.Subtitle.subtitleColor)
    private var subtitleColor
    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize

    /// The current scrubbed seconds for UI presentation and editing.
    ///
    /// - Note: This value is boxed to avoid unnecessary updates
    ///         for views that do not implement the current value.
    @BoxedPublished
    private var scrubbedSeconds: Duration = .zero

    @Router
    private var router

    @State
    private var audioOffset: Duration = .zero
    @State
    private var isAspectFilled: Bool = false
    @State
    private var isGestureLocked: Bool = false
    @State
    private var isScrubbing: Bool = false
    @State
    private var subtitleOffset: Duration = .zero

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

                        manager.seconds = newSeconds
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
                .environmentObject(manager)
                .environmentObject(_scrubbedSeconds.box)
        }
    }

    var body: some View {
        playerView
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: audioOffset) { newValue in
                vlcUIProxy.setAudioDelay(newValue)
            }
            .onChange(of: isAspectFilled) { newValue in
                UIView.animate(withDuration: 0.2) {
                    vlcUIProxy.aspectFill(newValue ? 1 : 0)
                }
            }
            .onChange(of: isScrubbing) { isScrubbing in
                guard !isScrubbing else { return }

                manager.seconds = scrubbedSeconds
                manager.proxy?.setSeconds(scrubbedSeconds)
            }
            .onChange(of: subtitleColor) { newValue in
                vlcUIProxy.setSubtitleColor(.absolute(newValue.uiColor))
            }
            .onChange(of: subtitleFontName) { newValue in
                vlcUIProxy.setSubtitleFont(newValue)
            }
            .onChange(of: subtitleOffset) { newValue in
                vlcUIProxy.setSubtitleDelay(newValue)
            }
            .onChange(of: subtitleSize) { newValue in
                vlcUIProxy.setSubtitleSize(.absolute(25 - newValue))
            }
            .onReceive(manager.events) { @MainActor event in
                switch event {
                case .playbackStopped:
                    vlcUIProxy.stop()
                    router.dismiss()
                case let .itemChanged(playbackItem: item):
                    isAspectFilled = false
                    audioOffset = .zero
                    subtitleOffset = .zero

                    scrubbedSeconds = item.baseItem.startSeconds ?? .zero
                    vlcUIProxy.playNewMedia(item.vlcConfiguration)
                }
            }
    }
}
