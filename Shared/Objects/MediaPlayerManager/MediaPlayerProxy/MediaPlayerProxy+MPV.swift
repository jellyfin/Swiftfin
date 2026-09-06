//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import MPVUI
import SwiftUI

@MainActor
class MPVMediaPlayerProxy: @MainActor VideoMediaPlayerProxy,
    @MainActor MediaPlayerOffsetConfigurable
{

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)
    let videoSize: PublishedBox<CGSize> = .init(initialValue: .zero)
    // MPVUI does not currently expose frame statistics.
    let droppedFrames: PublishedBox<Int> = .init(initialValue: 0)
    let corruptedFrames: PublishedBox<Int> = .init(initialValue: 0)
    let player = MPVPlayer()

    weak var manager: MediaPlayerManager? {
        didSet {
            for var observer in observers {
                observer.manager = manager
            }
        }
    }

    var observers: [any MediaPlayerObserver] = [
        NowPlayableObserver(),
    ]

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.stop()
    }

    func jumpForward(_ seconds: Duration) {
        setSeconds(player.position + seconds)
    }

    func jumpBackward(_ seconds: Duration) {
        setSeconds(player.position - seconds)
    }

    func setSeconds(_ seconds: Duration) {
        player.seek(to: seconds)
    }

    func setRate(_ rate: Float) {
        player.setPlaybackRate(Double(rate))
    }

    func setAudioStream(_ stream: MediaStream) {
        setTrack(stream.index, type: .audio)
    }

    func setSubtitleStream(_ stream: MediaStream) {
        setTrack(stream.index, type: .subtitle)
    }

    private func setTrack(_ index: Int?, type: MPVTrackType) {
        let tracks = player.mediaInformation.tracks.filter { $0.type == type }

        guard let index, index >= 0 else {
            if tracks.contains(where: \.isSelected) {
                player.disableTrack(type)
            }
            return
        }

        if let track = tracks.first(where: { $0.mpvID == index }), !track.isSelected {
            player.selectTrack(track)
        }
    }

    func setAspectFill(_ aspectFill: Bool) {
        player.setProperty("panscan", to: aspectFill ? "1" : "0")
    }

    func setAudioOffset(_ seconds: Duration) {
        player.setAudioDelay(seconds)
    }

    func setSubtitleOffset(_ seconds: Duration) {
        player.setSubtitleDelay(seconds)
    }

    var videoPlayerBody: some View {
        MPVPlayerView()
            .environmentObject(self)
    }
}

extension MPVMediaPlayerProxy {

    struct MPVPlayerView: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var proxy: MPVMediaPlayerProxy

        @State
        private var loadedItem: MediaPlayerItem?
        @State
        private var loadedSubtitleIndexes: Set<Int> = []
        @State
        private var textSubtitles = TextSubtitlePresentation()

        private var player: MPVPlayer {
            proxy.player
        }

        private var subtitleVideoSize: CGSize? {
            guard let dimensions = player.mediaInformation.dimensions else { return nil }
            var width = CGFloat(dimensions.effectiveWidth)
            var height = CGFloat(dimensions.effectiveHeight)
            let rotation = ((player.mediaInformation.rotation % 360) + 360) % 360
            if rotation == 90 || rotation == 270 {
                swap(&width, &height)
            }
            return CGSize(width: width, height: height)
        }

        private func load(_ item: MediaPlayerItem) {
            guard loadedItem !== item else { return }
            loadedItem = item
            loadedSubtitleIndexes.removeAll()
            item.setTrackIndexes(.init())
            proxy.isBuffering.value = true

            let start = max(.zero, (item.baseItem.startSeconds ?? .zero) - .seconds(Defaults[.VideoPlayer.resumeOffset]))
            player.load(item.url, autoPlay: manager.playbackRequestStatus == .playing, startTime: item.baseItem.isLiveStream ? nil : start)
            proxy.setRate(manager.rate)
            proxy.setAspectFill(false)
        }

        private func updateTracks(for item: MediaPlayerItem) {
            guard player.mediaInformation.sourceURL == item.url, player.mediaInformation.tracks.isNotEmpty else { return }

            switch player.state {
            case .idle, .loading, .ended, .stopped, .failed:
                return
            default:
                break
            }

            let indexMap = MediaTrackIndexMap.mpv(
                mediaStreams: item.mediaSource.mediaStreams ?? [],
                tracks: player.mediaInformation.tracks,
                isTranscoding: item.mediaSource.transcodingURL != nil,
                selectedAudioStreamIndex: item.selectedAudioStreamIndex
            )
            item.setTrackIndexes(indexMap)

            for stream in item.subtitleStreams.sidecarSubtitles {
                guard let index = stream.index,
                      indexMap.playerIndex(for: index) == nil,
                      let client = manager.userSession?.client,
                      let url = stream.url(with: client),
                      loadedSubtitleIndexes.insert(index).inserted
                else { continue }

                // Tag sidecars so a failed load cannot shift the remaining stream mappings.
                player.command("sub-add", arguments: [url.absoluteString, "auto", "swiftfin-subtitle-\(index)"])
            }
        }

        private func updateState(_ state: MPVPlaybackState) {
            proxy.isBuffering.value = state.isTransient

            switch state {
            case .loading:
                loadedSubtitleIndexes.removeAll()
            case .playing:
                manager.setPlaybackRequestStatus(status: .playing)
            case .paused:
                manager.setPlaybackRequestStatus(status: .paused)
            case .ended:
                guard manager.playbackItem?.baseItem.isLiveStream == false else { return }
                manager.seconds = player.position
                manager.ended()
            case let .failed(error):
                manager.error(error)
            case .idle, .ready, .buffering, .seeking, .stopped:
                break
            }
        }

        var body: some View {
            if let item = manager.playbackItem, manager.state != .stopped {
                MPVVideoPlayer(player: player)
                    .overlay {
                        TextSubtitleOverlay(
                            snapshot: loadedItem === item ? textSubtitles.snapshot : TextSubtitleSnapshot(),
                            videoSize: subtitleVideoSize,
                            isAspectFilled: containerState.isAspectFilled
                        )
                    }
                    .task(id: ObjectIdentifier(item)) {
                        await textSubtitles.observe(player) {
                            load(item)
                        }
                    }
                    .onDisappear {
                        textSubtitles.clear()
                    }
                    .onChange(of: player.position) {
                        if !containerState.isScrubbing {
                            containerState.scrubbedSeconds.value = player.position
                        }
                        manager.seconds = player.position
                    }
                    .onChange(of: player.state) {
                        updateState(player.state)
                        if player.state == .ready || player.state == .playing || player.state == .paused {
                            updateTracks(for: item)
                        }
                    }
                    .onChange(of: player.mediaInformation.tracks) {
                        updateTracks(for: item)
                    }
                    .onChange(of: player.mediaInformation.dimensions) {
                        let dimensions = player.mediaInformation.dimensions
                        proxy.videoSize.value = CGSize(width: dimensions?.effectiveWidth ?? 0, height: dimensions?.effectiveHeight ?? 0)
                    }
                    .onChange(of: manager.rate) {
                        proxy.setRate(manager.rate)
                    }
            }
        }
    }
}

extension MediaTrackIndexMap {

    /// mpv numbers tracks separately by type; Jellyfin uses global stream indexes.
    static func mpv(
        mediaStreams: [MediaStream],
        tracks: [MPVMediaTrack],
        isTranscoding: Bool,
        selectedAudioStreamIndex: Int?
    ) -> MediaTrackIndexMap {
        var map = MediaTrackIndexMap()

        for (streamType, trackType) in [(MediaStreamType.audio, MPVTrackType.audio), (.subtitle, .subtitle)] {
            let streams = mediaStreams.filter { $0.type == streamType && $0.isExternal != true }
                .sorted { ($0.index ?? -1) < ($1.index ?? -1) }
            let internalTracks = tracks.filter { $0.type == trackType && !$0.isExternal }

            if isTranscoding {
                if streamType == .audio, let index = selectedAudioStreamIndex, let track = internalTracks.first {
                    map.setPlayerIndex(track.mpvID, for: index)
                }
            } else {
                for (stream, track) in zip(streams, internalTracks) {
                    if let index = stream.index {
                        map.setPlayerIndex(track.mpvID, for: index)
                    }
                }
            }
        }

        for stream in mediaStreams.sidecarSubtitles {
            if let index = stream.index,
               let track = tracks.first(where: { $0.type == .subtitle && $0.isExternal && $0.title == "swiftfin-subtitle-\(index)" })
            {
                map.setPlayerIndex(track.mpvID, for: index)
            }
        }

        return map
    }
}
