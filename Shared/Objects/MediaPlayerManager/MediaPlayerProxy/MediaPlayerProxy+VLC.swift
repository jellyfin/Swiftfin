//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI
import VLCUI

class VLCMediaPlayerProxy: VideoMediaPlayerProxy,
    MediaPlayerOffsetConfigurable,
    MediaPlayerSubtitleConfigurable
{

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)
    let videoSize: PublishedBox<CGSize> = .init(initialValue: .zero)
    let vlcUIProxy: VLCVideoPlayer.Proxy = .init()

    weak var manager: MediaPlayerManager? {
        didSet {
            for var o in observers {
                o.manager = manager
            }
        }
    }

    var observers: [any MediaPlayerObserver] = [
        NowPlayableObserver(),
    ]

    func play() {
        vlcUIProxy.play()
    }

    func pause() {
        vlcUIProxy.pause()
    }

    func stop() {
        vlcUIProxy.stop()
    }

    func jumpForward(_ seconds: Duration) {
        vlcUIProxy.jumpForward(seconds)
    }

    func jumpBackward(_ seconds: Duration) {
        vlcUIProxy.jumpBackward(seconds)
    }

    func setRate(_ rate: Float) {
        vlcUIProxy.setRate(.absolute(rate))
    }

    func setSeconds(_ seconds: Duration) {
        vlcUIProxy.setSeconds(seconds)
    }

    func setAudioStream(_ stream: MediaStream) {
        vlcUIProxy.setAudioTrack(.absolute(stream.index ?? -1))
    }

    func setSubtitleStream(_ stream: MediaStream) {
        vlcUIProxy.setSubtitleTrack(.absolute(stream.index ?? -1))
    }

    func setAspectFill(_ aspectFill: Bool) {
        vlcUIProxy.aspectFill(aspectFill ? 1 : 0)
    }

    func setAudioOffset(_ seconds: Duration) {
        vlcUIProxy.setAudioDelay(seconds)
    }

    func setSubtitleOffset(_ seconds: Duration) {
        vlcUIProxy.setSubtitleDelay(seconds)
    }

    func setSubtitleColor(_ color: Color) {
        vlcUIProxy.setSubtitleColor(.absolute(color.uiColor))
    }

    func setSubtitleFontName(_ fontName: String) {
        vlcUIProxy.setSubtitleFont(fontName)
    }

    func setSubtitleFontSize(_ fontSize: Int) {
        vlcUIProxy.setSubtitleSize(.absolute(fontSize))
    }

    @ViewBuilder
    var videoPlayerBody: some View {
        VLCPlayerView()
            .environmentObject(vlcUIProxy)
    }
}

extension VLCMediaPlayerProxy {

    struct VLCPlayerView: View {

        @Default(.VideoPlayer.Subtitle.subtitleColor)
        private var subtitleColor
        @Default(.VideoPlayer.Subtitle.subtitleFontName)
        private var subtitleFontName
        @Default(.VideoPlayer.Subtitle.subtitleSize)
        private var subtitleSize

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var proxy: VLCVideoPlayer.Proxy

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        private func vlcConfiguration(for item: MediaPlayerItem) -> VLCVideoPlayer.Configuration {
            let baseItem = item.baseItem
            let mediaSource = item.mediaSource

            var configuration = VLCVideoPlayer.Configuration(url: item.url)
            configuration.autoPlay = true

            let startSeconds = max(.zero, (baseItem.startSeconds ?? .zero) - Duration.seconds(Defaults[.VideoPlayer.resumeOffset]))

            if !baseItem.isLiveStream {
                configuration.startSeconds = startSeconds
                configuration.audioIndex = .absolute(mediaSource.defaultAudioStreamIndex ?? -1)
                configuration.subtitleIndex = .absolute(mediaSource.defaultSubtitleStreamIndex ?? -1)
            }

            configuration.subtitleSize = .absolute(25 - Defaults[.VideoPlayer.Subtitle.subtitleSize])
            configuration.subtitleColor = .absolute(Defaults[.VideoPlayer.Subtitle.subtitleColor].uiColor)

            if let font = UIFont(name: Defaults[.VideoPlayer.Subtitle.subtitleFontName], size: 1) {
                configuration.subtitleFont = .absolute(font)
            }

            configuration.playbackChildren = item.subtitleStreams
                .filter { $0.deliveryMethod == .external }
                .compactMap(\.asVLCPlaybackChild)

            return configuration
        }

        var body: some View {
            if let playbackItem = manager.playbackItem, manager.state != .stopped {
                VLCVideoPlayer(configuration: vlcConfiguration(for: playbackItem))
                    .proxy(proxy)
                    .onSecondsUpdated { newSeconds, info in
                        if !isScrubbing {
                            containerState.scrubbedSeconds.value = newSeconds
                        }

                        manager.seconds = newSeconds

                        if let proxy = manager.proxy as? any VideoMediaPlayerProxy {
                            proxy.videoSize.value = info.videoSize
                        }
                    }
                    .onStateUpdated { state, info in
                        manager.logger.trace("VLC state updated: \(state)")

                        switch state {
                        case .buffering,
                             .esAdded,
                             .opening:
                            // TODO: figure out when to properly set to false
                            manager.proxy?.isBuffering.value = true
                        case .ended:
                            // Live streams will send stopped/ended events
                            guard !playbackItem.baseItem.isLiveStream else { return }
                            manager.proxy?.isBuffering.value = false
                            manager.ended()
                        case .stopped: ()
                        // Stopped is ignored as the `MediaPlayerManager`
                        // should instead call this to be stopped, rather
                        // than react to the event.
                        case .error:
                            manager.proxy?.isBuffering.value = false
                            manager.error(ErrorMessage("VLC player is unable to perform playback"))
                        case .playing:
                            manager.proxy?.isBuffering.value = false
                            manager.setPlaybackRequestStatus(status: .playing)
                        case .paused:
                            manager.setPlaybackRequestStatus(status: .paused)
                        }

                        if let proxy = manager.proxy as? any VideoMediaPlayerProxy {
                            proxy.videoSize.value = info.videoSize
                        }
                    }
                    .onReceive(manager.$playbackItem) { playbackItem in
                        guard let playbackItem else { return }
                        proxy.playNewMedia(vlcConfiguration(for: playbackItem))
                    }
                    .backport
                    .onChange(of: manager.rate) { _, newValue in
                        proxy.setRate(.absolute(newValue))
                    }
                    .backport
                    .onChange(of: subtitleColor) { _, newValue in
                        if let proxy = proxy as? MediaPlayerSubtitleConfigurable {
                            proxy.setSubtitleColor(newValue)
                        }
                    }
                    .backport
                    .onChange(of: subtitleFontName) { _, newValue in
                        if let proxy = proxy as? MediaPlayerSubtitleConfigurable {
                            proxy.setSubtitleFontName(newValue)
                        }
                    }
                    .backport
                    .onChange(of: subtitleSize) { _, newValue in
                        if let proxy = proxy as? MediaPlayerSubtitleConfigurable {
                            proxy.setSubtitleFontSize(25 - newValue)
                        }
                    }
            }
        }
    }
}
