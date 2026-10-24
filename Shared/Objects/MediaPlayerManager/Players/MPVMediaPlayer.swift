//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import MPVUI
import Observation
import SwiftUI

@MainActor
@Observable
final class MPVMediaPlayer: VideoMediaPlayer, MediaPlayerOffsetProviding, MediaPlayerSecondarySubtitleProviding {

    let displayTitle = MediaPlayerType.mpv.displayTitle
    let mediaPlayerType: MediaPlayerType = .mpv
    let player = MPVPlayer(configuration: .init(audio: .init(audioSession: .hostManaged)))
    private let textSubtitles = TextSubtitlePresentation()
    private(set) var videoState = VideoPlaybackState()

    #if os(iOS)
    @ObservationIgnored
    private var automaticPiPObservation: AnyCancellable?
    #endif

    @ObservationIgnored
    private var isSeekReload = false
    @ObservationIgnored
    private var lastError: MPVPlayerError?
    @ObservationIgnored
    private var lastState: MPVPlaybackState?
    @ObservationIgnored
    private var lastTracks: [MPVMediaTrack] = []
    @ObservationIgnored
    private var loadedItem: MediaPlayerItem?
    @ObservationIgnored
    private var loadedSubtitleIndexes: Set<Int> = []
    @ObservationIgnored
    weak var mediaSession: MediaSession?
    @ObservationIgnored
    private var pendingSeek: PlaybackTimeline.Seek?
    @ObservationIgnored
    private var pendingPlaybackStatus: MediaSession.PlaybackRequestStatus?
    @ObservationIgnored
    private var playbackObservation: AnyCancellable?
    @ObservationIgnored
    private var sawSeeking = false
    @ObservationIgnored
    private var seekLatencyBeforeRequest: Double?
    @ObservationIgnored
    private var seekStartedAt: ContinuousClock.Instant?

    init() {
        #if os(iOS)
        automaticPiPObservation = observeAutomaticPictureInPicture()
        #endif
    }

    isolated deinit {
        stop()
    }

    func load(_ item: MediaPlayerItem) {
        stop()
        loadedItem = item
        item.setTrackIndexes(.init())

        textSubtitles.start(player) { [weak self] in
            guard let self else { return }

            loadedItem?.replaySubtitles?.refresh()
        }

        player.load(
            item.url,
            autoPlay: mediaSession?.playbackRequestStatus == .playing,
            startTime: item.baseItem.isLiveStream ? nil : item.baseItem.startSeconds
        )

        setRate(mediaSession?.rate ?? 1)
        item.applyPlaybackOffsets()
        observePlayback(of: item)
    }

    func play() {
        guard loadedItem != nil else { return }

        pendingPlaybackStatus = .playing
        player.play()
    }

    func pause() {
        guard loadedItem != nil else { return }

        pendingPlaybackStatus = .paused
        player.pause()
    }

    func stop() {
        playbackObservation = nil
        loadedItem = nil
        loadedSubtitleIndexes.removeAll()
        lastState = nil
        lastTracks = []

        cancelSeek()
        lastError = nil
        pendingPlaybackStatus = nil

        textSubtitles.clear()
        player.stop()

        videoState = VideoPlaybackState()
    }

    func seek(_ request: PlaybackTimeline.Seek) {
        guard loadedItem != nil, player.isSeekable || player.state == .ended else {
            mediaSession?.playerDidCompleteSeek(request, position: nil, from: self)
            return
        }

        pendingSeek = request
        player.clearLastError()
        lastError = nil

        seekLatencyBeforeRequest = player.playbackDiagnostics.seekLatencySeconds
        sawSeeking = false
        seekStartedAt = .now
        isSeekReload = player.state == .ended

        if isSeekReload, let loadedItem {
            loadedSubtitleIndexes.removeAll()
            player.load(loadedItem.url, autoPlay: mediaSession?.playbackRequestStatus == .playing, startTime: request.target)
        } else {
            player.seek(to: request.target)
        }
    }

    func cancelSeek() {
        pendingSeek = nil
        seekLatencyBeforeRequest = nil
        sawSeeking = false
        seekStartedAt = nil
        isSeekReload = false
    }

    func setRate(_ rate: Double) {
        player.setPlaybackRate(rate)
    }

    func setStream(_ stream: MediaStream) {
        switch stream.type {
        case .audio:
            // M3U Live TV reports -1 for an unknown index. Preserve mpv's audio selection.
            guard let index = stream.index, index >= 0 else { return }

            setTrack(index, type: .audio)

        case .subtitle:
            setSubtitle(stream.index, for: .primary)

        default:
            return
        }
    }

    private func setSubtitle(_ index: Int?, for role: MPVSubtitleRole) {
        guard loadedItem != nil else { return }

        let track = player.subtitleTracks.first { $0.mpvID == index }

        if player.selectedSubtitle(for: role)?.id != track?.id {
            player.selectSubtitle(track?.id, for: role)
        }
    }

    func setSecondarySubtitle(_ index: Int?) {
        setSubtitle(index, for: .secondary)
    }

    func setSecondarySubtitleOffset(_ seconds: Duration) {
        player.setSubtitleDelay(seconds, for: .secondary)
    }

    private func setTrack(_ index: Int?, type: MPVTrackType) {
        guard loadedItem != nil else { return }

        let tracks = player.mediaInformation.tracks.filter { $0.type == type }

        guard let index, index >= 0 else {
            if tracks.contains(where: \.isSelected) {
                player.disableTrack(type)
            }

            return
        }

        if let track = tracks.first(where: { $0.mpvID == index }), !track.isSelected {
            player.selectTrack(track.id)
        }
    }

    func setOffset(_ seconds: Duration, for type: MediaStreamType) {
        switch type {
        case .audio:
            player.setAudioDelay(seconds)

        case .subtitle:
            player.setSubtitleDelay(seconds)

        default:
            return
        }
    }

    func videoPlayerBody(layout: VideoPlayer.VideoLayout) -> some View {
        MPVVideoPlayerView(
            player: player,
            textSubtitles: textSubtitles,
            layout: layout,
            isPictureInPictureActive: isPiPActive
        )
    }

    /// MPVUI publishes through Observation. Observe it here so timing and state
    /// continue to reach the mediaSession when no video view is mounted.
    private func observePlayback(of item: MediaPlayerItem) {
        let observation = MediaPlayerObservation { [player] in
            (
                player.state, player.position, player.mediaInformation, player.playbackDiagnostics,
                player.isPaused, player.bufferStatus, player.isSeekable, player.duration, player.lastError
            )
        } onChange: { [weak self, weak item] _ in
            guard let self, let item, loadedItem === item else { return }

            updatePlayback(for: item)
        }

        // Initial delivery may synchronously end or replace playback.
        if loadedItem === item {
            playbackObservation = AnyCancellable(observation)
        }
    }

    private func updatePlayback(for item: MediaPlayerItem) {
        let state = player.state
        let position = player.position
        let information = player.mediaInformation
        let diagnostics = player.playbackDiagnostics
        let isPaused = player.isPaused
        let buffer = player.bufferStatus
        let isSeekable = player.isSeekable
        let duration = player.duration
        let error = player.lastError

        guard information.sourceURL == item.url else { return }

        mediaSession?.playerDidUpdatePosition(position, from: self)

        mediaSession?.playerDidUpdate(
            PlaybackState(
                isReady: diagnostics.startLatencySeconds != nil,
                isPlaying: state == .playing && !isPaused,
                isSeekable: isSeekable || isSeekReload || state == .ended,
                isSeeking: state == .seeking,
                duration: duration > .zero ? duration : nil,
                isBuffering: buffer.isBuffering
            ),
            from: self
        )

        let observed: MediaSession.PlaybackRequestStatus = isPaused ? .paused : .playing

        if diagnostics.startLatencySeconds != nil,
           pendingPlaybackStatus == nil || pendingPlaybackStatus == observed
        {
            pendingPlaybackStatus = nil
            mediaSession?.playerDidRequestPlayback(observed, from: self)
        }

        if let request = pendingSeek {
            sawSeeking = sawSeeking || state == .seeking

            let didRestart = isSeekReload
                ? diagnostics.startLatencySeconds != nil
                : diagnostics.seekLatencySeconds != seekLatencyBeforeRequest

            // Playback may have advanced while delivery to the main actor was delayed.
            let elapsed = seekStartedAt?.duration(to: .now) ?? .zero
            let advance = isPaused ? Duration.zero : elapsed * max(1, mediaSession?.rate ?? 1)

            if state != .loading, state != .seeking,
               sawSeeking || didRestart,
               position >= request.target - .seconds(1),
               position <= request.target + advance + .seconds(1)
            {
                cancelSeek()
                mediaSession?.playerDidCompleteSeek(request, position: position, from: self)
            } else if case let .commandFailed(context, _, _) = error, context == "Seek", error != lastError {
                cancelSeek()
                mediaSession?.playerDidCompleteSeek(request, position: nil, from: self)
            }
        }

        lastError = error

        let size: CGSize

        if let dimensions = information.dimensions {
            var width = CGFloat(dimensions.effectiveWidth)
            var height = CGFloat(dimensions.effectiveHeight)
            let rotation = ((information.rotation % 360) + 360) % 360

            if rotation == 90 || rotation == 270 {
                swap(&width, &height)
            }

            size = CGSize(width: width, height: height)
        } else {
            size = .zero
        }

        let videoState = VideoPlaybackState(
            videoSize: size,
            droppedFrames: Int(clamping: (diagnostics.decoderDroppedFrames ?? 0) + (diagnostics.outputDroppedFrames ?? 0))
        )

        if self.videoState != videoState {
            self.videoState = videoState
        }

        let stateChanged = lastState != state
        let tracksChanged = lastTracks != information.tracks

        lastState = state
        lastTracks = information.tracks

        if stateChanged {
            updateState(state, item: item)
        }

        guard loadedItem === item else { return }

        if stateChanged || tracksChanged {
            updateTracks(for: item)

            if state == .ready || state == .playing || state == .paused {
                item.applyPlaybackOffsets()
            }
        }
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
                  let client = mediaSession?.userSession.client,
                  let url = stream.url(with: client),
                  loadedSubtitleIndexes.insert(index).inserted
            else { continue }

            // Tag sidecars so a failed load cannot shift remaining stream mappings.
            player.command("sub-add", arguments: [url.absoluteString, "auto", "swiftfin-subtitle-\(index)"])
        }
    }

    private func updateState(_ state: MPVPlaybackState, item: MediaPlayerItem) {
        switch state {
        case .ended:
            guard !item.baseItem.isLiveStream else { return }

            mediaSession?.ended(from: self)

        case let .failed(error):
            mediaSession?.playerDidFail(error, from: self)

        case .idle, .loading, .ready, .playing, .paused, .buffering, .seeking, .stopped:
            break
        }
    }
}

// MARK: - Picture in picture

extension MPVMediaPlayer: MediaPlayerPictureInPictureProviding {

    var allowsAutomaticPiP: Bool {
        get {
            player.pictureInPicture.allowsAutomaticStartFromInline
        }
        set {
            player.pictureInPicture.allowsAutomaticStartFromInline = newValue
        }
    }

    var isPiPActive: Bool {
        player.pictureInPicture.isActive
    }

    var isPiPAvailable: Bool {
        player.pictureInPicture.isPossible && !player.pictureInPicture.isTransitioning
    }

    var isPiPTransitioning: Bool {
        player.pictureInPicture.isTransitioning
    }

    func startPiP() {
        player.pictureInPicture.start()
    }

    func stopPiP() {
        player.pictureInPicture.stop()
    }
}

extension MediaTrackIndexMap {

    /// mpv assigns indexes within each track type. Jellyfin uses global stream indexes.
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
                    if let index = stream.index, !stream.isSidecarSubtitle {
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

extension MPVMediaPlayer: MediaPlayerSubtitleCueProviding {

    func canObserveSubtitleCues(at playerIndex: Int) -> Bool {
        guard let track = player.subtitleTracks.first(where: { $0.mpvID == playerIndex }),
              let codec = track.codec?.lowercased() else { return false }

        // MPVUI's live semantic stream covers these formats. Native ASS and
        // bitmap rendering do not expose cue endings through that API.
        return ["subrip", "srt", "webvtt", "vtt", "ttml", "mov_text"].contains(codec)
    }

    var subtitleCues: Set<SubtitleCue> {
        Set((textSubtitles.snapshot?.regions ?? []).filter { !$0.text.isEmpty }.map {
            SubtitleCue(text: $0.text, track: $0.trackID?.mpvID ?? -1, secondary: $0.role == .secondary)
        })
    }
}
