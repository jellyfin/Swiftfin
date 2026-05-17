//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import Logging
import SwiftUI
import VLCUI

class VLCMediaPlayerProxy: VideoMediaPlayerProxy,
    MediaPlayerOffsetConfigurable,
    MediaPlayerSubtitleConfigurable
{

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)
    let videoSize: PublishedBox<CGSize> = .init(initialValue: .zero)
    let droppedFrames: PublishedBox<Int> = .init(initialValue: 0)
    let corruptedFrames: PublishedBox<Int> = .init(initialValue: 0)
    let vlcUIProxy: VLCVideoPlayer.Proxy = .init()

    private var hasRetriedCurrentItem = false

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
        let target: Duration

        if let runtime = manager?.item.runtime, let current = manager?.seconds {
            let remaining = max(.zero, runtime - current)
            target = min(seconds, remaining)
        } else {
            target = seconds
        }

        guard target > .zero else { return }

        vlcUIProxy.jumpForward(target)
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

        @State
        private var didScheduleLiveOverlayDismissal = false

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        private func vlcConfiguration(for item: MediaPlayerItem) -> VLCVideoPlayer.Configuration {
            let baseItem = item.baseItem
            let mediaSource = item.mediaSource

            // Normalize malformed URLs like .../stream%3F&DeviceId=... to .../stream?DeviceId=...
            let originalURL = item.url
            let fixedURL: URL = {
                let s = originalURL.absoluteString
                // Replace only the first occurrence of "%3F" (encoded question mark) with "?"
                if let range = s.range(of: "%3F") {
                    var corrected = s
                    corrected.replaceSubrange(range, with: "?")
                    if let url = URL(string: corrected) {
                        manager.logger.warning(
                            "Normalized malformed media URL for VLC",
                            metadata: [
                                "original": .stringConvertible(s),
                                "normalized": .stringConvertible(corrected)
                            ]
                        )
                        return url
                    }
                }
                return originalURL
            }()

            var configuration = VLCVideoPlayer.Configuration(url: fixedURL)
            configuration.autoPlay = true

            // Configure caching to better handle segmented livestreams and network variability
            if baseItem.isLiveStream {
                // Prefer higher live/network caching for HLS/DASH segmented livestreams
                configuration.options["live-caching"] = 1500
                configuration.options["network-caching"] = 2000
            } else {
                configuration.options["network-caching"] = 1500
                configuration.options["file-caching"] = 1000
            }

            let startSeconds = max(.zero, (baseItem.startSeconds ?? .zero) - Duration.seconds(Defaults[.VideoPlayer.resumeOffset]))

            if !baseItem.isLiveStream {
                configuration.startSeconds = startSeconds
                configuration.audioIndex = .absolute(mediaSource.defaultAudioStreamIndex ?? -1)
                configuration.subtitleIndex = .absolute(mediaSource.defaultSubtitleStreamIndex ?? -1)
            }

            // Compute and clamp subtitle size to a sane range
            let computedSubtitleSize = 25 - Defaults[.VideoPlayer.Subtitle.subtitleSize]
            let clampedSubtitleSize = max(8, min(36, computedSubtitleSize))
            configuration.subtitleSize = .absolute(clampedSubtitleSize)

            configuration.subtitleColor = .absolute(Defaults[.VideoPlayer.Subtitle.subtitleColor].uiColor)
            configuration.rate = .absolute(Defaults[.VideoPlayer.Playback.playbackRate])
            if let font = UIFont(name: Defaults[.VideoPlayer.Subtitle.subtitleFontName], size: 1) {
                configuration.subtitleFont = .absolute(font)
            }

            configuration.playbackChildren = item.subtitleStreams
                .filter { $0.deliveryMethod == .external }
                .compactMap(\.asVLCPlaybackChild)

            let audioIndexValue = baseItem.isLiveStream ? -1 : (mediaSource.defaultAudioStreamIndex ?? -1)
            let subtitleIndexValue = baseItem.isLiveStream ? -1 : (mediaSource.defaultSubtitleStreamIndex ?? -1)
            let childrenCount = configuration.playbackChildren.count

            manager.logger.info(
                "Built VLC configuration",
                metadata: [
                    "url": .stringConvertible(fixedURL.absoluteString),
                    "startSeconds": .stringConvertible(startSeconds.seconds),
                    "audioIndex": .stringConvertible(audioIndexValue),
                    "subtitleIndex": .stringConvertible(subtitleIndexValue),
                    "externalSubtitleChildren": .stringConvertible(childrenCount)
                ]
            )

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
                            proxy.droppedFrames.value = info.statistics.lostPictures
                            proxy.corruptedFrames.value = info.statistics.demuxCorrupted
                        }

                        if playbackItem.baseItem.isLiveStream, !didScheduleLiveOverlayDismissal {
                            didScheduleLiveOverlayDismissal = true
                            containerState.timer.poke(interval: 3)
                        }
                    }
                    .onStateUpdated { state, info in
                        manager.logger.trace("VLC state updated: \(state)")

                        switch state {
                        case .buffering:
                            manager.proxy?.isBuffering.value = true
                        case .esAdded:
                            manager.proxy?.isBuffering.value = true
                        case .opening:
                            manager.proxy?.isBuffering.value = true
                            manager.logger.info(
                                "VLC opening media",
                                metadata: [
                                    "url": .stringConvertible(manager.playbackItem?.url.absoluteString ?? "unknown")
                                ]
                            )
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
                            let url = manager.playbackItem?.url.absoluteString ?? "unknown"
                            let secs = manager.seconds.seconds
                            manager.logger.error(
                                "VLC reported error",
                                metadata: [
                                    "url": .stringConvertible(url),
                                    "seconds": .stringConvertible(secs),
                                    "videoSize": .stringConvertible("\(info.videoSize.width)x\(info.videoSize.height)"),
                                    "lostPictures": .stringConvertible(info.statistics.lostPictures),
                                    "demuxCorrupted": .stringConvertible(info.statistics.demuxCorrupted)
                                ]
                            )
                            if let proxyOwner = manager.proxy as? VLCMediaPlayerProxy, proxyOwner.hasRetriedCurrentItem == false {
                                proxyOwner.hasRetriedCurrentItem = true
                                manager.logger.warning(
                                    "VLC error encountered — attempting single retry with increased caching",
                                    metadata: ["url": .stringConvertible(url), "seconds": .stringConvertible(secs)]
                                )
                                if let item = manager.playbackItem {
                                    var cfg = vlcConfiguration(for: item)
                                    // Bump caching a bit more for the retry to stabilize playback
                                    if item.baseItem.isLiveStream {
                                        cfg.options["live-caching"] = 2500
                                        cfg.options["network-caching"] = 3000
                                    } else {
                                        cfg.options["network-caching"] = 2000
                                        cfg.options["file-caching"] = 1500
                                    }
                                    proxy.playNewMedia(cfg)
                                    return
                                }
                            }
                            manager.error(ErrorMessage("VLC player is unable to perform playback"))
                        case .playing:
                            manager.proxy?.isBuffering.value = false
                            manager.setPlaybackRequestStatus(status: .playing)
                            if playbackItem.baseItem.isLiveStream {
                                proxy.setSubtitleTrack(.absolute(playbackItem.selectedSubtitleStreamIndex ?? -1))

                                if !didScheduleLiveOverlayDismissal {
                                    didScheduleLiveOverlayDismissal = true
                                    containerState.timer.poke(interval: 3)
                                }
                            }
                            manager.logger.info(
                                "VLC playing",
                                metadata: [
                                    "videoSize": .stringConvertible("\(info.videoSize.width)x\(info.videoSize.height)"),
                                    "lostPictures": .stringConvertible(info.statistics.lostPictures),
                                    "demuxCorrupted": .stringConvertible(info.statistics.demuxCorrupted)
                                ]
                            )
                        case .paused:
                            manager.setPlaybackRequestStatus(status: .paused)
                        }

                        if let proxy = manager.proxy as? any VideoMediaPlayerProxy {
                            proxy.videoSize.value = info.videoSize
                        }
                    }
                    .onReceive(manager.$playbackItem) { playbackItem in
                        didScheduleLiveOverlayDismissal = false
                        guard let playbackItem else { return }
                        if let proxyOwner = manager.proxy as? VLCMediaPlayerProxy {
                            proxyOwner.hasRetriedCurrentItem = false
                        }
                        manager.logger.info(
                            "VLC playNewMedia",
                            metadata: ["url": .stringConvertible(playbackItem.url.absoluteString)]
                        )
                        proxy.playNewMedia(vlcConfiguration(for: playbackItem))
                        proxy.setSubtitleTrack(.absolute(playbackItem.selectedSubtitleStreamIndex ?? -1))
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
