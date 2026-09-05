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
import SwiftUI
import SwiftVLC

@MainActor
class VLCMediaPlayerProxy: VideoMediaPlayerProxy,
    MediaPlayerOffsetConfigurable,
    MediaPlayerSubtitleConfigurable
{

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)
    let videoSize: PublishedBox<CGSize> = .init(initialValue: .zero)
    let droppedFrames: PublishedBox<Int> = .init(initialValue: 0)
    let corruptedFrames: PublishedBox<Int> = .init(initialValue: 0)
    let player = Player()

    private var pendingStartTime: Duration?

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
        if player.state == .paused {
            player.resume()
        } else {
            do {
                try player.play()
            } catch {
                failPlayback(error)
            }
        }
    }

    func pause() {
        player.pause()
    }

    func stop() {
        pendingStartTime = nil
        isBuffering.value = false
        player.stop()
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

        player.jump(by: target)
    }

    func jumpBackward(_ seconds: Duration) {
        player.jump(by: .zero - seconds)
    }

    func setRate(_ rate: Float) {
        do {
            try player.setPlaybackRate(PlaybackRate(rate))
        } catch {
            log(error)
        }
    }

    func setSeconds(_ seconds: Duration) {
        guard player.isSeekable else { return }

        pendingStartTime = nil

        do {
            try player.seek(to: seconds)
        } catch {
            log(error)
        }
    }

    func setAudioStream(_ stream: MediaStream) {
        guard let index = stream.index, player.audioTracks.indices.contains(index) else {
            player.selectedAudioTrack = nil
            return
        }

        let track = player.audioTracks[index]
        guard player.selectedAudioTrack != track else { return }
        player.selectedAudioTrack = track
    }

    func setSubtitleStream(_ stream: MediaStream) {
        guard let index = stream.index, player.subtitleTracks.indices.contains(index) else {
            player.selectedSubtitleTrack = nil
            return
        }

        let track = player.subtitleTracks[index]
        guard player.selectedSubtitleTrack != track else { return }
        player.selectedSubtitleTrack = track
    }

    func setAspectFill(_ aspectFill: Bool) {
        player.aspectRatio = aspectFill ? .fill : .default
    }

    func setAudioOffset(_ seconds: Duration) {
        do {
            try player.setAudioDelay(seconds)
        } catch {
            log(error)
        }
    }

    func setSubtitleOffset(_ seconds: Duration) {
        do {
            try player.setSubtitleDelay(seconds)
        } catch {
            log(error)
        }
    }

    func setSubtitleConfiguration(_ configuration: SubtitleConfiguration) {
        player.setSubtitleScale(.init(approximatePoints: Double(25 - configuration.size)))
    }

    @ViewBuilder
    var videoPlayerBody: some View {
        VLCPlayerView(proxy: self)
    }

    private func log(_ error: Error) {
        manager?.logger.warning("SwiftVLC operation rejected: \(error)")
    }

    private func failPlayback(_ error: Error) {
        manager?.logger.error("SwiftVLC error: \(error)")
        manager?.error(ErrorMessage("VLC player error: \(error.localizedDescription)"))
    }

    /// Applies the resume position as an absolute seek once libVLC has
    /// established the media timeline. Using `:start-time` rebases some
    /// inputs and makes the player's reported time relative to that offset.
    @discardableResult
    private func applyPendingStartTimeIfPossible() -> Bool {
        guard let pendingStartTime else { return false }
        guard player.isSeekable else { return false }

        self.pendingStartTime = nil

        do {
            try player.seek(to: pendingStartTime)
            manager?.seconds = pendingStartTime
        } catch {
            log(error)
        }

        return true
    }

    private func play(_ item: MediaPlayerItem, subtitleConfiguration: SubtitleConfiguration) {
        do {
            let media = try Media(url: item.url)

            let startSeconds = max(
                .zero,
                (item.baseItem.startSeconds ?? .zero) - Duration.seconds(Defaults[.VideoPlayer.resumeOffset])
            )

            pendingStartTime = !item.baseItem.isLiveStream && startSeconds > .zero ? startSeconds : nil

            if let client = manager?.userSession?.client {
                for subtitle in item.subtitleStreams.sidecarSubtitles {
                    guard let url = subtitle.url(with: client) else { continue }
                    try media.addSlave(from: url, type: .subtitle)
                }
            }

            // libVLC 4 applies font and color options when opening media.
            // Size remains adjustable during playback through SubtitleScale.
            media.addOption(":freetype-font=\(subtitleConfiguration.fontName)")
            if let color = Int(subtitleConfiguration.color.hexString.prefix(6), radix: 16) {
                media.addOption(":freetype-color=\(color)")
            }

            try player.play(media)
            setSubtitleConfiguration(subtitleConfiguration)
        } catch {
            pendingStartTime = nil
            failPlayback(error)
        }
    }
}

extension VLCMediaPlayerProxy {

    struct VLCPlayerView: View {

        @ObservedObject
        var proxy: VLCMediaPlayerProxy

        @Default(.VideoPlayer.Subtitle.configuration)
        private var subtitleConfiguration

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        var body: some View {
            if let playbackItem = manager.playbackItem, manager.state != .stopped {
                VideoView(proxy.player)
                    .task(id: ObjectIdentifier(playbackItem)) {
                        proxy.play(playbackItem, subtitleConfiguration: subtitleConfiguration)
                    }
                    .onChange(of: proxy.player.currentTime) { _, newSeconds in
                        // Ignore an initial or already superseded timestamp while
                        // the absolute resume seek is being established.
                        guard proxy.player.state == .playing || proxy.player.state == .paused,
                              !proxy.applyPendingStartTimeIfPossible(),
                              newSeconds == proxy.player.currentTime
                        else { return }

                        if !isScrubbing {
                            containerState.scrubbedSeconds.value = newSeconds
                        }

                        manager.seconds = newSeconds
                        if proxy.player.state == .playing {
                            proxy.isBuffering.value = false
                        }

                        proxy.videoSize.value = proxy.player.videoSize ?? .zero
                        if let statistics = proxy.player.statistics {
                            proxy.droppedFrames.value = Int(clamping: statistics.lostPictures)
                            proxy.corruptedFrames.value = Int(clamping: statistics.demuxCorrupted)
                        }
                    }
                    .onChange(of: proxy.player.state) { _, state in
                        manager.logger.trace("SwiftVLC state updated: \(state)")

                        switch state {
                        case .buffering, .opening:
                            proxy.isBuffering.value = true
                        case .error:
                            proxy.isBuffering.value = false
                            manager.error(ErrorMessage("VLC player is unable to perform playback"))
                        case .playing:
                            proxy.applyPendingStartTimeIfPossible()
                            proxy.isBuffering.value = false
                            manager.setPlaybackRequestStatus(status: .playing)
                            proxy.setRate(manager.rate)
                            playbackItem.switchTrack(type: .audio, index: playbackItem.selectedAudioStreamIndex)
                            playbackItem.switchTrack(type: .subtitle, index: playbackItem.selectedSubtitleStreamIndex)
                        case .paused:
                            proxy.isBuffering.value = false
                            manager.setPlaybackRequestStatus(status: .paused)
                        case .idle, .stopped, .stopping: ()
                        }

                        proxy.videoSize.value = proxy.player.videoSize ?? .zero
                    }
                    .onChange(of: proxy.player.bufferFill) { _, fill in
                        guard proxy.player.state == .playing else { return }
                        if fill < 0.9 {
                            proxy.isBuffering.value = true
                        } else if fill >= 1 {
                            proxy.isBuffering.value = false
                        }
                    }
                    .onChange(of: proxy.player.isSeekable) { _, isSeekable in
                        guard isSeekable else { return }
                        proxy.applyPendingStartTimeIfPossible()
                    }
                    .onChange(of: proxy.player.didReachEnd) { _, didReachEnd in
                        guard didReachEnd, manager.playbackItem?.baseItem.isLiveStream == false else { return }
                        // libVLC resets its clock on stop. Report the completed
                        // timeline before the manager decides whether to advance.
                        if let runtime = playbackItem.baseItem.runtime {
                            manager.seconds = runtime
                        }
                        proxy.isBuffering.value = false
                        manager.ended()
                    }
                    .onChange(of: proxy.player.audioTracks) {
                        playbackItem.switchTrack(type: .audio, index: playbackItem.selectedAudioStreamIndex)
                    }
                    .onChange(of: proxy.player.subtitleTracks) {
                        let subtitleTracks = proxy.player.subtitleTracks.enumerated().map {
                            (playerIndex: $0.offset, id: $0.element.id)
                        }
                        playbackItem.updateSubtitleTrackMapping(subtitleTracks: subtitleTracks)
                    }
                    .onChange(of: manager.rate) {
                        proxy.setRate(manager.rate)
                    }
                    .onChange(of: subtitleConfiguration) {
                        proxy.setSubtitleConfiguration(subtitleConfiguration)
                    }
            }
        }
    }
}
