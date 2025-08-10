//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI
import VLCUI

class VLCMediaPlayerProxy: MediaPlayerProxy {

    let vlcUIProxy: VLCVideoPlayer.Proxy = .init()

    func play() {
        vlcUIProxy.play()
    }

    func pause() {
        vlcUIProxy.pause()
    }

    func jumpForward(_ seconds: Duration) {
        vlcUIProxy.jumpForward(Int(seconds.components.seconds))
    }

    func jumpBackward(_ seconds: Duration) {
        vlcUIProxy.jumpBackward(Int(seconds.components.seconds))
    }

    func setRate(_ rate: Float) {
        vlcUIProxy.setRate(.absolute(rate))
    }

    func setSeconds(_ seconds: Duration) {
        vlcUIProxy.setSeconds(seconds)
    }

    func stop() {
        vlcUIProxy.stop()
    }

    func setAudioStream(_ stream: MediaStream) {
        vlcUIProxy.setAudioTrack(.absolute(stream.index ?? -1))
    }

    func setSubtitleStream(_ stream: MediaStream) {
        vlcUIProxy.setSubtitleTrack(.absolute(stream.index ?? -1))
    }

    func makeVideoPlayerBody(manager: MediaPlayerManager) -> some View {
        _VideoPlayerBody(manager: manager)
            .environmentObject(vlcUIProxy)
    }
}

extension VLCMediaPlayerProxy {

    struct _VideoPlayerBody: View {

        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>
        @EnvironmentObject
        private var vlcUIProxy: VLCVideoPlayer.Proxy

        @ObservedObject
        var manager: MediaPlayerManager

        private var scrubbedSeconds: Duration {
            get { scrubbedSecondsBox.value }
            nonmutating set { scrubbedSecondsBox.value = newValue }
        }

        var body: some View {
            if let playbackItem = manager.playbackItem {
                VLCVideoPlayer(configuration: playbackItem.vlcConfiguration)
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
        }
    }
}
