//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import Logging
import MPVUI
import Observation
import SwiftUI

@MainActor
@Observable
final class MPVMediaPlayer {

    let displayTitle = MediaPlayerType.mpv.displayTitle
    let playbackProfile = PlaybackProfile.local(.mpv)

    let player = MPVPlayer(configuration: .init(audio: .init(audioSession: .hostManaged)))
    private let textSubtitles = TextSubtitlePresentation()

    @ObservationIgnored
    weak var mediaSession: MediaSession?

    private(set) var videoState = VideoPlaybackState()

    @ObservationIgnored
    private var loadedItem: MediaPlayerItem?
    @ObservationIgnored
    private var loadGeneration: UInt64?

    @ObservationIgnored
    private var eventObservation: AnyCancellable?
    @ObservationIgnored
    private var timingObservation: AnyCancellable?

    @ObservationIgnored
    private var seekTask: Task<Void, Never>?
    @ObservationIgnored
    private var pendingSeek: PlaybackTimeline.Seek?
    @ObservationIgnored
    private var pendingPlaybackStatus: MediaSession.PlaybackRequestStatus?

    @ObservationIgnored
    private var subtitleLoads: [Int: Task<Bool, Never>] = [:]

    @ObservationIgnored
    private var observedState: MPVPlaybackState = .idle
    @ObservationIgnored
    private var observedPaused = true
    @ObservationIgnored
    private var observedPlayback = PlaybackState()
    @ObservationIgnored
    private var information = MPVMediaInformation.empty

    @ObservationIgnored
    private var appliedAudioOffset: Duration?
    @ObservationIgnored
    private var appliedSubtitleOffsets: [MPVSubtitleRole: Duration] = [:]

    @ObservationIgnored
    private var automaticPiPRequested = false
    #if os(iOS)
    @ObservationIgnored
    private var automaticPiPObservation: AnyCancellable?
    #endif

    init() {
        let logger = Logger.swiftfin()

        player.logHandler = { message in
            let level: Logger.Level

            switch message.level {
            case .fatal, .error:
                level = .error

            case .warning:
                level = .warning

            default:
                return
            }

            logger.log(level: level, "mpv [\(message.prefix)]: \(Self.redacted(message.message))")
        }

        #if os(iOS)
        automaticPiPObservation = observeAutomaticPictureInPicture()
        #endif
    }

    isolated deinit {
        stop()
    }
}

extension MPVMediaPlayer: VideoMediaPlayer {

    func load(_ item: MediaPlayerItem) {
        clearItem()
        loadedItem = item

        player.load(
            item.url,
            playAutomatically: mediaSession?.playbackRequestStatus == .playing,
            startTime: item.baseItem.isLiveStream ? nil : item.baseItem.startSeconds
        )
        loadGeneration = player.generation

        textSubtitles.start(player) { [weak self] in
            self?.loadedItem?.replaySubtitles?.refresh()
        }

        item.setTrackIndexes(.init())
        setRate(mediaSession?.rate ?? 1)
        item.applyPlaybackOffsets()
        observePlayback(of: item)
    }

    func play() {
        guard loadedItem != nil else {
            return
        }

        pendingPlaybackStatus = .playing
        player.play()
    }

    func pause() {
        guard loadedItem != nil else {
            return
        }

        pendingPlaybackStatus = .paused
        player.pause()
    }

    func stop() {
        clearItem()
        player.stop()
    }

    func seek(_ request: PlaybackTimeline.Seek) {
        guard loadedItem != nil, player.isSeekable || player.state == .ended else {
            mediaSession?.playerDidCompleteSeek(request, position: nil, from: self)
            return
        }

        cancelSeek()
        pendingSeek = request
        player.clearLastError()

        let generation = player.generation

        seekTask = Task { [weak self, player] in
            let position: Duration?

            do {
                position = try await player.seekAndWait(to: request.target).position
            } catch is CancellationError {
                return
            } catch {
                position = nil
            }

            guard !Task.isCancelled, let self, loadGeneration == generation, pendingSeek?.id == request.id else {
                return
            }

            pendingSeek = nil
            seekTask = nil
            mediaSession?.playerDidCompleteSeek(request, position: position, from: self)

            if loadGeneration == generation, observedState == .ended, loadedItem?.baseItem.isLiveStream == false {
                mediaSession?.ended(from: self)
            }
        }
    }

    func cancelSeek() {
        pendingSeek = nil
        seekTask?.cancel()
        seekTask = nil
    }

    func setRate(_ rate: Double) {
        player.setPlaybackRate(rate)
    }

    func setStream(_ stream: MediaStream) {
        switch stream.type {
        case .audio:
            // M3U Live TV reports -1 for an unknown index. Preserve mpv's audio selection.
            guard let index = stream.index, index >= 0 else {
                return
            }

            if let track = player.audioTracks.first(where: { $0.mpvID == index }), !track.isSelected {
                player.selectTrack(track.id)
            }

        case .subtitle:
            setSubtitle(stream.index, for: .primary)

        default:
            break
        }
    }

    func videoPlayerBody(layout: VideoPlayer.VideoLayout) -> some View {
        MPVVideoPlayerView(player: player, textSubtitles: textSubtitles, layout: layout, isPictureInPictureActive: isPiPActive)
    }

    /// Replacing an item keeps MPVUI's native client and renderer available for the next load.
    private func clearItem() {
        eventObservation = nil
        timingObservation = nil

        loadedItem = nil
        loadGeneration = nil

        cancelSeek()

        for task in subtitleLoads.values {
            task.cancel()
        }

        subtitleLoads.removeAll()

        pendingPlaybackStatus = nil
        observedState = .idle
        observedPaused = true
        observedPlayback = PlaybackState()
        information = .empty

        appliedAudioOffset = nil
        appliedSubtitleOffsets.removeAll()

        textSubtitles.clear()
        videoState = VideoPlaybackState()
    }

    private func setSubtitle(_ index: Int?, for role: MPVSubtitleRole) {
        guard loadedItem != nil else {
            return
        }

        let track = player.subtitleTracks.first { $0.mpvID == index }

        if player.selectedSubtitle(for: role)?.id != track?.id {
            player.selectSubtitle(track?.id, for: role)
        }
    }

    private func observePlayback(of item: MediaPlayerItem) {
        let events = player.makeEventStream()
        let timing = player.makeTimingStream()

        eventObservation = Task { [weak self, weak item] in
            for await event in events {
                guard !Task.isCancelled, let self, let item, loadedItem === item, event.generation == loadGeneration else {
                    return
                }

                receive(event, for: item)
            }
        }
        .asAnyCancellable()

        timingObservation = Task { [weak self, weak item] in
            for await value in timing {
                guard !Task.isCancelled, let self, let item, loadedItem === item, value.generation == loadGeneration else {
                    return
                }

                updateTiming(
                    position: value.position,
                    duration: value.duration,
                    seekable: value.isSeekable,
                    buffering: value.buffer.isBuffering
                )
            }
        }
        .asAnyCancellable()
    }

    private func receive(_ event: MPVPlaybackEvent, for item: MediaPlayerItem) {
        switch event.change {
        case let .snapshot(snapshot):
            observedState = snapshot.state
            observedPaused = snapshot.isPaused
            observedPlayback.isReady = snapshot.isPlaybackReady

            updateTiming(
                position: snapshot.position,
                duration: snapshot.duration,
                seekable: snapshot.isSeekable,
                buffering: snapshot.buffer.isBuffering
            )

            updateMediaInformation(snapshot.mediaInformation, for: item)
            publishPlaybackState()

        case let .pauseChanged(paused):
            observedPaused = paused
            publishPlaybackState()

        case let .readinessChanged(ready):
            observedPlayback.isReady = ready
            publishPlaybackState()

            if ready, loadedItem === item {
                updateTracks(for: item)
            }

        case let .stateChanged(state):
            observedState = state
            publishPlaybackState()

            guard loadedItem === item else {
                return
            }

            switch state {
            case .ended:
                mediaSession?.playerDidUpdatePosition(player.position, from: self)

                if pendingSeek == nil, !item.baseItem.isLiveStream {
                    mediaSession?.ended(from: self)
                }

            case let .failed(error):
                mediaSession?.logger.error("MPV playback failed: \(Self.redacted(error.message))")
                mediaSession?.playerDidFail(error, from: self)

            case .ready:
                updateTracks(for: item)

            default:
                break
            }

        case let .mediaInformationChanged(value):
            updateMediaInformation(value, for: item)

        case .videoFeaturesChanged:
            updateAutomaticPiP()

        case .audioChanged, .chapterChanged, .error, .seekCompleted, .externalTrackLoaded:
            break
        }
    }

    private func updateTiming(position: Duration, duration: Duration, seekable: Bool, buffering: Bool) {
        mediaSession?.playerDidUpdatePosition(position, from: self)

        let previous = observedPlayback

        observedPlayback.duration = duration > .zero ? duration : nil
        observedPlayback.isSeekable = seekable
        observedPlayback.isBuffering = buffering

        if previous != observedPlayback {
            publishPlaybackState()
        }
    }

    private func publishPlaybackState() {
        var state = observedPlayback
        state.isPlaying = observedState == .playing && !observedPaused
        state.isSeeking = observedState == .seeking
        state.isSeekable = state.isSeekable || observedState == .ended

        mediaSession?.playerDidUpdate(state, from: self)

        let observed: MediaSession.PlaybackRequestStatus = observedPaused ? .paused : .playing

        if state.isReady, pendingPlaybackStatus == nil || pendingPlaybackStatus == observed {
            pendingPlaybackStatus = nil
            mediaSession?.playerDidRequestPlayback(observed, from: self)
        }
    }

    private func updateMediaInformation(_ value: MPVMediaInformation, for item: MediaPlayerItem) {
        let tracksChanged = information.tracks != value.tracks
        information = value

        let size = value.presentationDimensions.map { CGSize(width: $0.width, height: $0.height) } ?? .zero

        if videoState.videoSize != size {
            videoState.videoSize = size
        }

        if tracksChanged {
            updateTracks(for: item)
        }

        updateAutomaticPiP()
    }

    private func updateTracks(for item: MediaPlayerItem) {
        guard !information.tracks.isEmpty, player.isPlaybackReady, loadedItem === item else {
            return
        }

        let map = MediaTrackIndexMap.mpv(
            mediaStreams: item.mediaSource.mediaStreams ?? [],
            tracks: information.tracks,
            isTranscoding: item.mediaSource.transcodingURL != nil,
            selectedAudioStreamIndex: item.selectedAudioStreamIndex
        )

        if item.indexMap != map {
            item.setTrackIndexes(map)
        }
    }

    private nonisolated static func redacted(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"(?i)\b(?:https?|rtsp|rtmp|ftp|file)://[^\s]+"#, with: "<URL>", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension MPVMediaPlayer: MediaPlayerOffsetProviding {

    func setOffset(_ seconds: Duration, for type: MediaStreamType) {
        switch type {
        case .audio:
            guard appliedAudioOffset != seconds else {
                return
            }

            appliedAudioOffset = seconds
            player.setAudioDelay(seconds)

        case .subtitle:
            setSubtitleOffset(seconds, for: .primary)

        default:
            break
        }
    }

    private func setSubtitleOffset(_ seconds: Duration, for role: MPVSubtitleRole) {
        guard appliedSubtitleOffsets[role] != seconds else {
            return
        }

        appliedSubtitleOffsets[role] = seconds
        player.setSubtitleDelay(seconds, for: role)
    }
}

extension MPVMediaPlayer: MediaPlayerSecondarySubtitleProviding {

    func setSecondarySubtitle(_ index: Int?) {
        setSubtitle(index, for: .secondary)
    }

    func setSecondarySubtitleOffset(_ seconds: Duration) {
        setSubtitleOffset(seconds, for: .secondary)
    }
}

extension MPVMediaPlayer: MediaPlayerExternalSubtitleProviding {

    /// Imports only requested sidecars. A failed import is removed so a later request can retry.
    func prepareSubtitle(_ stream: MediaStream) async -> Bool {
        guard let item = loadedItem,
              let generation = loadGeneration,
              stream.isSidecarSubtitle,
              let index = stream.index,
              index >= 0
        else {
            return false
        }

        if let mapped = item.indexMap.playerIndex(for: index), mapped >= 0 {
            return true
        }

        if let pending = subtitleLoads[index] {
            return await pending.value
        }

        guard let client = mediaSession?.userSession.client, let url = stream.url(with: client) else {
            return false
        }

        let descriptor = MPVExternalTrack(
            url: url,
            type: .subtitle,
            clientID: MPVTrackIdentity.subtitleID(index),
            title: stream.displayTitle,
            language: stream.language,
            selection: .unselected
        )

        let task = Task { [weak self, weak item, player] in
            do {
                _ = try await player.loadExternalTrack(descriptor)

                guard !Task.isCancelled, let self, let item, loadedItem === item, loadGeneration == generation else {
                    return false
                }

                // Mapping applies the latest primary/secondary choices, even if they changed during the read.
                updateMediaInformation(player.mediaInformation, for: item)

                return true
            } catch is CancellationError {
                return false
            } catch {
                guard !Task.isCancelled, let self, loadGeneration == generation else {
                    return false
                }

                let message = (error as? MPVPlayerError)?.message ?? String(describing: error)
                mediaSession?.logger.error("MPV subtitle import failed: \(Self.redacted(message))")

                return false
            }
        }

        subtitleLoads[index] = task

        let loaded = await task.value

        if loadGeneration == generation {
            subtitleLoads[index] = nil
        }

        return loaded
    }
}

extension MPVMediaPlayer: MediaPlayerPictureInPictureProviding {

    var allowsAutomaticPiP: Bool {
        get {
            automaticPiPRequested
        }
        set {
            automaticPiPRequested = newValue
            updateAutomaticPiP()
        }
    }

    private var canCarrySubtitlesInPiP: Bool {
        player.subtitleTracks
            .filter(\.isSelected)
            .allSatisfy { track in
                let capability = track.subtitleCapabilities?.supportsLiveText == true
                    ? player.videoFeatureCapabilities.pictureInPictureSubtitles
                    : player.videoFeatureCapabilities.nativeSubtitles

                return capability.availability == .available
            }
    }

    var isPiPActive: Bool {
        player.pictureInPicture.isActive
    }

    var isPiPAvailable: Bool {
        player.pictureInPicture.isPossible && !player.pictureInPicture.isTransitioning && canCarrySubtitlesInPiP
    }

    var isPiPTransitioning: Bool {
        player.pictureInPicture.isTransitioning
    }

    func startPiP() {
        if isPiPAvailable {
            player.pictureInPicture.start()
        }
    }

    func stopPiP() {
        player.pictureInPicture.stop()
    }

    private func updateAutomaticPiP() {
        let supported = canCarrySubtitlesInPiP
        player.pictureInPicture.allowsAutomaticStartFromInline = automaticPiPRequested && supported

        if !supported, player.pictureInPicture.isActive {
            player.pictureInPicture.stop()
        }
    }
}

extension MPVMediaPlayer: MediaPlayerSubtitleCueProviding {

    var subtitleCues: Set<SubtitleCue> {
        Set(
            (textSubtitles.snapshot?.regions ?? [])
                .filter(\.text.isNotEmpty)
                .map {
                    SubtitleCue(text: $0.text, track: $0.trackID?.mpvID ?? -1, secondary: $0.role == .secondary)
                }
        )
    }

    func canObserveSubtitleCues(at playerIndex: Int) -> Bool {
        player.subtitleTracks.first { $0.mpvID == playerIndex }?.subtitleCapabilities?.supportsLiveText == true
    }
}
