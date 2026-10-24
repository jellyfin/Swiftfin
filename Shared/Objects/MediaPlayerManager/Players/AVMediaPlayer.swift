//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import AVKit
import Combine
import Foundation
@preconcurrency import JellyfinAPI
import Observation
import SwiftUI

@MainActor
@Observable
final class AVMediaPlayer: NSObject, MediaPlayer, MediaPlayerMetadataProviding {

    var allowsAutomaticPiP = false {
        didSet {
            #if os(iOS)
            pipController?.canStartPictureInPictureAutomaticallyFromInline = allowsAutomaticPiP
            #endif
        }
    }

    let displayTitle = MediaPlayerType.avPlayer.displayTitle
    private(set) var isPiPActive: Bool = false
    private(set) var isPiPAvailable: Bool = false
    private(set) var isPiPTransitioning = false
    let playbackProfile = PlaybackProfile.local(.avPlayer)
    let player: AVPlayer
    let playerLayer: AVPlayerLayer
    private(set) var subtitleCues: Set<SubtitleCue> = []
    private(set) var videoState = VideoPlaybackState()

    #if os(iOS)
    @ObservationIgnored
    private var automaticPiPObservation: AnyCancellable?
    #endif

    @ObservationIgnored
    private var cachedAudioGroup: AVMediaSelectionGroup?
    @ObservationIgnored
    private var cachedSubtitleGroup: AVMediaSelectionGroup?

    #if os(tvOS)
    @ObservationIgnored
    private weak var displayManager: AVDisplayManager? {
        didSet {
            observeDisplayModeSwitch()
            Task { [weak self] in await self?.updatePreferredDisplayCriteria() }
        }
    }

    @ObservationIgnored
    private var displayModeSwitchObserver: NSKeyValueObservation?
    #endif

    @ObservationIgnored
    private weak var loadedItem: MediaPlayerItem?
    @ObservationIgnored
    private var generation = 0
    @ObservationIgnored
    private var isReady = false
    @ObservationIgnored
    weak var mediaSession: MediaSession?
    @ObservationIgnored
    private var pendingPlaybackStatus: MediaSession.PlaybackRequestStatus?
    @ObservationIgnored
    private var pendingSeek: PlaybackTimeline.Seek?
    @ObservationIgnored
    private var pipAvailableObserver: NSKeyValueObservation?
    @ObservationIgnored
    private var pipController: AVPictureInPictureController?
    @ObservationIgnored
    private var playbackObservations: Set<AnyCancellable> = []
    @ObservationIgnored
    private var preparationTask: AnyCancellable?
    @ObservationIgnored
    private var subtitleOutput: AVPlayerItemLegibleOutput?

    override init() {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)

        super.init()

        player.appliesMediaSelectionCriteriaAutomatically = false
        player.allowsExternalPlayback = true

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

        let playerItem = AVPlayerItem(url: item.url)

        let output = AVPlayerItemLegibleOutput()
        output.suppressesPlayerRendering = false
        output.setDelegate(self, queue: .main)
        playerItem.add(output)
        subtitleOutput = output

        playerItem.externalMetadata = item.baseItem.avMetadata
        player.replaceCurrentItem(with: playerItem)
        observePlayback(of: playerItem, item: item, generation: generation)

        setupPiP()

        #if os(tvOS)
        observeDisplayModeSwitch()
        #endif
    }

    func updateMetadata(for item: MediaPlayerItem, artwork: UIImage?) {
        guard loadedItem === item, let playerItem = player.currentItem else { return }

        playerItem.externalMetadata = item.baseItem.nowPlayableStaticMetadata().avMetadata(artwork: artwork)
    }

    func play() {
        guard isReady else { return }

        pendingPlaybackStatus = .playing
        player.rate = Float(mediaSession?.rate ?? 1)
    }

    func pause() {
        pendingPlaybackStatus = .paused
        player.pause()
    }

    func stop() {
        loadedItem = nil
        generation &+= 1

        subtitleOutput?.setDelegate(nil, queue: nil)

        if let subtitleOutput {
            player.currentItem?.remove(subtitleOutput)
        }

        subtitleOutput = nil
        subtitleCues = []

        isReady = false
        preparationTask = nil
        cancelSeek()
        pendingPlaybackStatus = nil

        playbackObservations.removeAll()
        cachedAudioGroup = nil
        cachedSubtitleGroup = nil

        teardownPiP()
        player.pause()
        player.replaceCurrentItem(with: nil)

        videoState = VideoPlaybackState()

        #if os(tvOS)
        displayModeSwitchObserver = nil
        displayManager?.preferredDisplayCriteria = nil
        #endif
    }

    func setRate(_ rate: Double) {
        guard isReady, player.rate != 0 else { return }

        player.rate = Float(rate)
    }

    func seek(_ request: PlaybackTimeline.Seek) {
        guard isReady, let playerItem = player.currentItem else {
            mediaSession?.playerDidCompleteSeek(request, position: nil, from: self)
            return
        }

        pendingSeek = request

        let generation = generation

        player.seek(
            to: CMTime(seconds: request.target.seconds, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { [weak self] finished in
            Task { @MainActor [weak self] in
                guard let self, isCurrent(playerItem, generation: generation), pendingSeek?.id == request.id else { return }

                pendingSeek = nil

                let time = player.currentTime()

                mediaSession?.playerDidCompleteSeek(
                    request,
                    position: finished && time.isNumeric ? .seconds(time.seconds) : nil,
                    from: self
                )

                updatePlaybackState()
            }
        }

        updatePlaybackState()
    }

    func cancelSeek() {
        pendingSeek = nil
        player.currentItem?.cancelPendingSeeks()
    }

    func setStream(_ stream: MediaStream) {
        let group: AVMediaSelectionGroup?

        switch stream.type {
        case .audio:
            group = cachedAudioGroup
        case .subtitle:
            group = cachedSubtitleGroup
        default:
            return
        }

        guard let item = player.currentItem, let group else { return }
        guard let index = stream.index, let option = group.options[safe: index] else {
            if stream.type == .subtitle {
                item.select(nil, in: group)
            }

            return
        }

        item.select(option, in: group)
    }

    private func isCurrent(_ playerItem: AVPlayerItem, generation: Int) -> Bool {
        self.generation == generation && player.currentItem === playerItem
    }
}

// MARK: - Playback observation

extension AVMediaPlayer {

    private func observePlayback(of playerItem: AVPlayerItem, item: MediaPlayerItem, generation: Int) {
        let timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1000),
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.isCurrent(playerItem, generation: generation), self.isReady else { return }

                let time = self.player.currentTime()

                if time.isNumeric {
                    self.mediaSession?.playerDidUpdatePosition(.seconds(time.seconds), from: self)
                }

                self.updatePlaybackState()
            }
        }

        AnyCancellable { [player] in player.removeTimeObserver(timeObserver) }
            .store(in: &playbackObservations)

        player.publisher(for: \.timeControlStatus, options: [.new])
            .sink { [weak self] status in
                Task { @MainActor [weak self] in
                    guard let self, self.isCurrent(playerItem, generation: generation) else { return }

                    self.updatePlaybackState()

                    guard self.isReady, self.player.timeControlStatus == status else { return }

                    let observed: MediaSession.PlaybackRequestStatus

                    switch status {
                    case .playing:
                        observed = .playing
                    case .paused:
                        observed = .paused
                    default:
                        return
                    }

                    guard self.pendingSeek == nil,
                          self.pendingPlaybackStatus == nil || self.pendingPlaybackStatus == observed else { return }

                    self.pendingPlaybackStatus = nil

                    if self.isPiPActive || self.player.isExternalPlaybackActive {
                        self.mediaSession?.playerDidRequestPlayback(observed, from: self)
                    }
                }
            }

            .store(in: &playbackObservations)

        let updateState: @Sendable () -> Void = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, isCurrent(playerItem, generation: generation) else { return }

                updatePlaybackState()
            }
        }

        playerItem.publisher(for: \.seekableTimeRanges, options: [.initial, .new])
            .sink { _ in updateState() }
            .store(in: &playbackObservations)

        playerItem.publisher(for: \.duration, options: [.new])
            .sink { _ in updateState() }
            .store(in: &playbackObservations)

        player.publisher(for: \.reasonForWaitingToPlay, options: [.new])
            .sink { _ in updateState() }
            .store(in: &playbackObservations)

        playerItem.publisher(for: \.presentationSize, options: [.initial, .new])
            .sink { [weak self] size in
                Task { @MainActor [weak self] in
                    guard let self, self.isCurrent(playerItem, generation: generation) else { return }

                    if self.videoState.videoSize != size {
                        self.videoState.videoSize = size
                    }
                }
            }

            .store(in: &playbackObservations)

        NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, self.isCurrent(playerItem, generation: generation), !item.baseItem.isLiveStream else { return }

                    if let runtime = item.baseItem.runtime {
                        self.mediaSession?.playerDidUpdatePosition(runtime, from: self)
                    } else if playerItem.duration.isNumeric {
                        self.mediaSession?.playerDidUpdatePosition(.seconds(playerItem.duration.seconds), from: self)
                    }

                    self.mediaSession?.ended(from: self)
                }
            }

            .store(in: &playbackObservations)

        NotificationCenter.default
            .publisher(for: AVPlayerItem.newAccessLogEntryNotification, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, self.isCurrent(playerItem, generation: generation),
                          let event = playerItem.accessLog()?.events.last, event.numberOfDroppedVideoFrames >= 0
                    else { return }

                    if self.videoState.droppedFrames != event.numberOfDroppedVideoFrames {
                        self.videoState.droppedFrames = event.numberOfDroppedVideoFrames
                    }
                }
            }

            .store(in: &playbackObservations)

        playerItem.publisher(for: \.status, options: [.initial, .new])
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, self.isCurrent(playerItem, generation: generation) else { return }

                    switch playerItem.status {
                    case .failed:
                        let message = playerItem.error?.localizedDescription ?? self.player.error?.localizedDescription ?? L10n.unknownError
                        self.mediaSession?.playerDidFail(ErrorMessage("AVPlayer error: \(message)"), from: self)

                    case .readyToPlay:
                        guard self.preparationTask == nil else { return }

                        self.preparationTask = Task { [weak self] in
                            await self?.prepare(playerItem, item: item, generation: generation)
                        }
                        .asAnyCancellable()

                    default:
                        break
                    }
                }
            }
            .store(in: &playbackObservations)
    }

    private func prepare(_ playerItem: AVPlayerItem, item: MediaPlayerItem, generation: Int) async {
        let audioGroup = try? await playerItem.asset.loadMediaSelectionGroup(for: .audible)
        let subtitleGroup = try? await playerItem.asset.loadMediaSelectionGroup(for: .legible)
        guard !Task.isCancelled, isCurrent(playerItem, generation: generation) else { return }

        cachedAudioGroup = audioGroup
        cachedSubtitleGroup = subtitleGroup

        var indexMap = MediaTrackIndexMap()

        for (streams, group) in [(item.audioStreams, audioGroup), (item.subtitleStreams, subtitleGroup)] {
            guard let group else { continue }

            let internalStreams = streams.filter { $0.isExternal != true }

            for stream in streams {
                guard let index = stream.index,
                      let option = selectionOption(matching: index, in: group, from: internalStreams),
                      let playerIndex = group.options.firstIndex(of: option)
                else { continue }

                indexMap.setPlayerIndex(playerIndex, for: index)
            }
        }

        item.setTrackIndexes(indexMap)

        #if os(tvOS)
        await updatePreferredDisplayCriteria()

        guard !Task.isCancelled, isCurrent(playerItem, generation: generation) else { return }

        #endif

        let startSeconds = item.baseItem.startSeconds ?? .zero

        if !item.baseItem.isLiveStream {
            let finished = await player.seek(
                to: CMTime(seconds: startSeconds.seconds, preferredTimescale: 600),
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )

            guard !Task.isCancelled, isCurrent(playerItem, generation: generation) else { return }
            guard finished else {
                mediaSession?.playerDidFail(ErrorMessage(L10n.unableToSeek), from: self)
                return
            }
        }

        guard !Task.isCancelled, isCurrent(playerItem, generation: generation) else { return }

        isReady = true
        let time = player.currentTime()

        if time.isNumeric {
            mediaSession?.playerDidUpdatePosition(.seconds(time.seconds), from: self)
        }

        updatePlaybackState()

        if mediaSession?.playbackRequestStatus == .playing {
            play()
        }
    }

    private func selectionOption(
        matching index: Int,
        in group: AVMediaSelectionGroup,
        from streams: [MediaStream]
    ) -> AVMediaSelectionOption? {
        if streams.count == group.options.count,
           let position = streams.firstIndex(where: { $0.index == index })
        {
            return group.options[position]
        }

        if group.options.count == 1 {
            return group.options.first
        }

        if let language = streams.first(property: \.index, equalTo: index)?.language {
            return AVMediaSelectionGroup.mediaSelectionOptions(
                from: group.options,
                filteredAndSortedAccordingToPreferredLanguages: [language]
            )
            .first
        }

        return nil
    }

    private func updatePlaybackState() {
        guard let item = player.currentItem else { return }

        let duration: Duration? = item.duration.isNumeric && item.duration.seconds > 0 ? .seconds(item.duration.seconds) : nil

        var snapshot = PlaybackState(
            isReady: isReady,
            isPlaying: player.timeControlStatus == .playing,
            isSeekable: duration != nil || item.seekableTimeRanges.isNotEmpty,
            duration: duration,
            isBuffering: player.timeControlStatus == .waitingToPlayAtSpecifiedRate &&
                (player.reasonForWaitingToPlay == .toMinimizeStalls || player.reasonForWaitingToPlay == .evaluatingBufferingRate)
        )

        #if os(tvOS)
        snapshot.isWaitingForDisplay = displayManager?.isDisplayModeSwitchInProgress == true
        #endif

        mediaSession?.playerDidUpdate(snapshot, from: self)
    }
}

// MARK: - Picture in picture

extension AVMediaPlayer: MediaPlayerPictureInPictureProviding {

    private func setupPiP() {
        guard player.currentItem != nil, pipController == nil, AVPictureInPictureController.isPictureInPictureSupported() else { return }

        let controller = AVPictureInPictureController(playerLayer: playerLayer)
        pipController = controller
        controller?.delegate = self
        controller?.requiresLinearPlayback = false

        #if os(iOS)
        controller?.canStartPictureInPictureAutomaticallyFromInline = allowsAutomaticPiP
        #endif

        pipAvailableObserver = controller?.observe(\.isPictureInPicturePossible, options: [.initial, .new]) { [weak self] controller, _ in
            let available = controller.isPictureInPicturePossible

            Task { @MainActor [weak self] in
                guard let self, self.pipController === controller else { return }

                self.isPiPAvailable = available
            }
        }
    }

    func startPiP() {
        pipController?.startPictureInPicture()
    }

    func stopPiP() {
        pipController?.stopPictureInPicture()
    }

    private func teardownPiP() {
        pipAvailableObserver = nil
        pipController?.delegate = nil
        pipController?.stopPictureInPicture()
        pipController = nil
        isPiPActive = false
        isPiPAvailable = false
        isPiPTransitioning = false
    }
}

extension AVMediaPlayer: AVPictureInPictureControllerDelegate {

    nonisolated func pictureInPictureControllerWillStartPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor [weak self] in
            guard let self, self.pipController === controller else { return }

            self.isPiPTransitioning = true
        }
    }

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor [weak self] in
            guard let self, self.pipController === controller else { return }

            self.isPiPActive = true
            self.isPiPTransitioning = false
        }
    }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor [weak self] in
            guard let self, self.pipController === controller else { return }

            self.isPiPActive = false
            self.isPiPTransitioning = false
        }
    }

    nonisolated func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        Task { @MainActor [weak self] in
            guard let self, self.pipController === controller else { return }

            self.isPiPActive = false
            self.isPiPTransitioning = false
            self.mediaSession?.logger.error("Unable to start Picture in Picture: \(error.localizedDescription)")
        }
    }

    nonisolated func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}

// MARK: - Video surface

extension AVMediaPlayer: VideoMediaPlayer {

    func videoPlayerBody(layout: VideoPlayer.VideoLayout) -> some View {
        AVVideoPlayerView(player: self, layout: layout)
    }

    func videoSurfaceDidMove(to window: UIWindow) {
        setupPiP()

        #if os(tvOS)
        displayManager = window.avDisplayManager
        #endif
    }
}

#if os(tvOS)
extension AVMediaPlayer {

    private func observeDisplayModeSwitch() {
        displayModeSwitchObserver = displayManager?.observe(\.isDisplayModeSwitchInProgress, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self, self.player.currentItem != nil else { return }

                self.updatePlaybackState()
            }
        }
    }

    private func updatePreferredDisplayCriteria() async {
        guard let displayManager,
              let playerItem = player.currentItem,
              playerItem.status == .readyToPlay,
              let track = try? await playerItem.asset.loadTracks(withMediaType: .video).first,
              let formatDescription = try? await track.load(.formatDescriptions).first
        else { return }

        let nominalFrameRate = await (try? track.load(.nominalFrameRate)) ?? 0
        guard !Task.isCancelled, player.currentItem === playerItem, self.displayManager === displayManager else { return }

        displayManager.preferredDisplayCriteria = AVDisplayCriteria(refreshRate: nominalFrameRate, formatDescription: formatDescription)
    }
}
#endif

extension AVMediaPlayer: MediaPlayerSubtitleCueProviding, @preconcurrency AVPlayerItemLegibleOutputPushDelegate {

    func canObserveSubtitleCues(at playerIndex: Int) -> Bool {
        cachedSubtitleGroup?.options.indices.contains(playerIndex) == true
    }

    func legibleOutput(
        _ output: AVPlayerItemLegibleOutput,
        didOutputAttributedStrings strings: [NSAttributedString],
        nativeSampleBuffers _: [Any],
        forItemTime _: CMTime
    ) {
        guard output === subtitleOutput else { return }

        subtitleCues = Set(strings.map(\.string).filter(\.isNotEmpty).map { SubtitleCue(text: $0) })
        loadedItem?.replaySubtitles?.refresh()
    }

    func outputSequenceWasFlushed(_ output: AVPlayerItemOutput) {
        guard output === subtitleOutput else { return }

        subtitleCues = []
        loadedItem?.replaySubtitles?.refresh()
    }
}
