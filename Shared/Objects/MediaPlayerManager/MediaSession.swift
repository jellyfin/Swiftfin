//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI
import Logging
import StatefulMacros

@MainActor
@Observable
@StatefulObservable
final class MediaSession {

    typealias ItemResolver = @MainActor (PlaybackIntent, PlaybackProfile, UserSession) async throws -> MediaPlayerItem

    private let resolveItem: ItemResolver

    @CasePathable
    enum Action {

        case cancel
        case error
        case _resolve(intent: PlaybackIntent, id: UUID)
        case _beginPlayback

        var transition: Transition {
            switch self {
            case .cancel:
                .to(.stopped)
            case .error:
                .none
            case ._resolve:
                .to(.loadingItem, then: .preparing).invalid(.stopped).onRepeat(.cancel)
            case ._beginPlayback:
                .to(.playback).required(.preparing)
            }
        }
    }

    enum State {

        case initial
        case loadingItem
        case preparing
        case playback
        case error
        case stopped
    }

    enum PlaybackEvent {

        case positionChanged
        case seekRequested(PlaybackTimeline.Seek, origin: Duration)
        case seekCompleted(PlaybackTimeline.Seek, position: Duration?, hasPendingSeek: Bool)
    }

    @ObservationIgnored
    private let playbackEventSubject = PassthroughSubject<PlaybackEvent, Never>()

    var playbackEvents: AnyPublisher<PlaybackEvent, Never> {
        playbackEventSubject.eraseToAnyPublisher()
    }

    enum PlaybackRequestStatus {

        case playing
        case paused
    }

    let id = UUID()
    var commandError: String?
    private(set) var intent: PlaybackIntent
    private(set) var isSeeking = false
    private var isAdvancingQueue = false
    let logger = Logger.swiftfin()
    private(set) var playbackItem: MediaPlayerItem?
    private(set) var playbackRequestStatus: PlaybackRequestStatus = .playing
    private(set) var playbackState = PlaybackState()
    private(set) var player: (any MediaPlayer)?
    private let progressReporter: MediaProgressReporter
    let queue: any MediaPlayerQueue?

    var rate: Double = Defaults[.VideoPlayer.Playback.playbackRate] {
        didSet {
            Defaults[.VideoPlayer.Playback.playbackRate] = rate
            player?.setRate(effectiveRate)
        }
    }

    var effectiveRate: Double {
        let range = player?.supportedRates ?? 0.1 ... 5
        return min(max(rate, range.lowerBound), range.upperBound)
    }

    var isRemotePlayback: Bool {
        player?.playbackLocation == .remote
    }

    var canReturnToLocalPlayback: Bool {
        isRemotePlayback && localPlayer != nil && state != .stopped && state != .error
    }

    @ObservationIgnored
    private var localPlayer: (any MediaPlayer)?
    @ObservationIgnored
    private var handoffRecovery: (player: any MediaPlayer, intent: PlaybackIntent)?
    @ObservationIgnored
    private var transferTask: Task<Void, Error>?
    @ObservationIgnored
    private var transferID = UUID()

    private(set) var seconds: Duration = .zero
    private(set) var observedSeconds: Duration = .zero

    @ObservationIgnored
    private var hasReportedPlayback = false
    @ObservationIgnored
    private lazy var playbackTransitions = MediaPlaybackTransitions(mediaSession: self)
    @ObservationIgnored
    private var resolutionID = UUID()
    @ObservationIgnored
    private var resolutionTask: AnyCancellable?
    @ObservationIgnored
    private var queueAdvanceTask: AnyCancellable?
    @ObservationIgnored
    private var seekDispatchTask: AnyCancellable?
    @ObservationIgnored
    private var seekTimeoutTask: AnyCancellable?
    @ObservationIgnored
    private var sessionObservation: AnyCancellable?
    @ObservationIgnored
    private var lifecycleObservation: AnyCancellable?
    @ObservationIgnored
    private var timeline = PlaybackTimeline()
    let userSession: UserSession

    var hasActivePlayback: Bool {
        player != nil && state != .error && state != .stopped
    }

    var canControlPlayback: Bool {
        (state == .preparing || state == .playback) && playbackState.isReady
    }

    var canSeek: Bool {
        canControlPlayback && playbackState.isSeekable && !item.isLiveStream
    }

    enum Activity: Equatable {

        case loading
        case buffering
        case seeking
        case switchingDisplay
    }

    var activity: Activity? {
        switch state {
        case .initial, .loadingItem:
            return .loading
        case .preparing where !playbackState.isReady:
            return .loading
        case .error, .stopped:
            return nil
        case .preparing, .playback:
            break
        }

        if isAdvancingQueue {
            return .loading
        }

        if isSeeking || playbackState.isSeeking {
            return .seeking
        }

        if playbackState.isWaitingForDisplay {
            return .switchingDisplay
        }

        return playbackState.isBuffering ? .buffering : nil
    }

    var item: BaseItemDto {
        playbackItem?.baseItem ?? intent.item
    }

    var playbackBitrate: PlaybackBitrate {
        intent.configuration.requestedBitrate
    }

    init(
        intent: PlaybackIntent,
        userSession: UserSession,
        reportQueue: MediaPlaybackReportQueue,
        resolveItem: @escaping ItemResolver = { try await MediaPlayerItemResolver.resolve($0, for: $1, userSession: $2) }
    ) {
        self.intent = intent
        self.userSession = userSession
        self.resolveItem = resolveItem
        self.queue = intent.queue
        self.progressReporter = MediaProgressReporter(userSession: userSession, reportQueue: reportQueue)

        progressReporter.mediaSession = self

        lifecycleObservation = core.statePublisher.sink { [weak self] state in
            // Error and cancel are special synchronous actions in StatefulMacros.
            // Cleanup follows their committed state, including generated action calls.
            if state == .error || state == .stopped {
                self?.tearDown()
            }
        }
    }

    isolated deinit {
        transferTask?.cancel()
        progressReporter.stop()
        player?.mediaSession = nil
        playbackItem?.mediaSession = nil
        player?.stop()
    }

    /// The session retains the engine independently of any mounted video surface.
    /// Reattaching the same engine is harmless; destinations change through transfer(to:).
    @discardableResult
    func attach(player: any MediaPlayer) -> Bool {
        guard state != .stopped else { return false }

        if let attached = self.player {
            return attached === player
        }

        guard player.mediaSession == nil else { return false }

        self.player = player
        localPlayer = player.playbackLocation == .local ? player : nil
        player.mediaSession = self
        resolve(intent)

        return true
    }

    @discardableResult
    func playNewItem(intent: PlaybackIntent) -> Task<Void, Never>? {
        guard state != .stopped else { return nil }
        guard player != nil else {
            self.intent = intent
            return nil
        }

        var nextIntent = intent
        if canControlPlayback, let playbackItem {
            nextIntent.configuration.continuation = MediaPlaybackContinuation(
                item: playbackItem.baseItem,
                source: playbackItem.mediaSource,
                audioStreamIndex: playbackItem.configuration.audioStreamIndex,
                subtitleStreamIndex: playbackItem.configuration.subtitleStreamIndex,
                configuration: userSession.user.data.configuration
            )
        }

        handoffRecovery = nil
        return resolve(nextIntent)
    }

    /// Re-negotiate for each destination, retaining the local engine and desired transport state.
    @discardableResult
    func transfer(to destination: any MediaPlayer) -> Task<Void, Never>? {
        guard let player, player !== destination, state != .stopped, state != .error,
              destination.mediaSession == nil else { return nil }

        let snapshot = currentIntent()
        if handoffRecovery == nil {
            handoffRecovery = (player, snapshot)
        }
        if player.playbackLocation == .local {
            localPlayer = player
        }
        return resolve(snapshot, using: destination)
    }

    @discardableResult
    func returnToLocalPlayback() -> Task<Void, Never>? {
        guard canReturnToLocalPlayback, let localPlayer else { return nil }

        handoffRecovery = nil
        return resolve(currentIntent(), using: localPlayer)
    }

    private func currentIntent() -> PlaybackIntent {
        guard playbackItem != nil else { return intent }

        var intent = playbackItem?.resumingIntent(at: seconds) ?? intent
        intent.queue = queue
        return intent
    }

    /// A single cancellable request owns installation. Superseded results cannot restart playback.
    @discardableResult
    private func resolve(_ intent: PlaybackIntent, using destination: (any MediaPlayer)? = nil) -> Task<Void, Never>? {
        guard let player, state != .stopped else { return nil }

        var intent = intent
        intent.queue = queue

        core.cancelAll()
        playbackTransitions.reset()
        resolutionTask = nil
        queueAdvanceTask = nil
        isAdvancingQueue = false

        let id = UUID()
        resolutionID = id
        commandError = nil

        progressReporter.stop()
        discardUnstartedItem()
        playbackItem?.mediaSession = nil
        playbackItem = nil
        hasReportedPlayback = false

        resetPlayback()
        player.pause()
        if let destination {
            player.mediaSession = nil
            playbackTransitions.stopPictureInPicture()
            let previousTransfer = transferTask
            transferID = UUID()
            // This barrier survives a superseding resolution or item change.
            transferTask = Task {
                let previousResult = await previousTransfer?.result
                defer { player.stop() }
                try await player.stopForTransfer()
                if case let .failure(error)? = previousResult {
                    throw error
                }
            }
            self.player = destination
            destination.mediaSession = self
        }
        let destinationPlayer = destination ?? player
        self.intent = intent

        let core = core

        let task = Task { [weak self] in
            // Await the macro's committed preparing state before loading the engine.
            // The manager binds Now Playing/audio before load can start producing audio.
            try? await core.send(\._resolve, (intent: intent, id: id))

            guard !Task.isCancelled, let self, resolutionID == id, state == .preparing,
                  let item = playbackItem else { return }

            destinationPlayer.load(item)

            guard resolutionID == id, state == .preparing, playbackItem === item else { return }

            destinationPlayer.setRate(effectiveRate)

            guard resolutionID == id, state == .preparing, playbackItem === item else { return }

            resolutionTask = nil

            if playbackState.isReady {
                beginPlayback()
            }

            item.activate()
        }

        resolutionTask = task.asAnyCancellable()

        return task
    }

    @Function(\Action.Cases._resolve)
    private func performResolve(intent: PlaybackIntent, id: UUID) async {
        guard let player, resolutionID == id, state != .stopped else { return }

        do {
            try Task.checkCancellation()
            let transferID = transferID
            if let transferTask {
                do {
                    try await transferTask.value
                } catch {
                    guard !Task.isCancelled, resolutionID == id, state != .stopped else { return }

                    playbackRequestStatus = .paused
                    commandError = L10n.unableToStopRemotePlayback
                }
            }
            try Task.checkCancellation()
            guard resolutionID == id, state != .stopped else { return }

            if self.transferID == transferID {
                transferTask = nil
            }
            let resolvedIntent = try await queue?.resolve(intent, userSession: userSession) ?? intent
            try Task.checkCancellation()
            guard resolutionID == id, state != .stopped else { return }

            self.intent = resolvedIntent
            let item = try await resolveItem(resolvedIntent, player.playbackProfile, userSession)
            guard !Task.isCancelled, resolutionID == id, state != .stopped else {
                await MediaProgressReporter.discard(item, session: userSession)
                return
            }

            player.stop()
            timeline.reset(position: item.baseItem.startSeconds ?? .zero)
            publishTimeline()

            playbackItem = item
            self.intent.configuration = item.configuration
            item.mediaSession = self

            observeSessionIfNeeded()
        } catch {
            guard resolutionID == id, !Task.isCancelled, state != .stopped else { return }

            fail(error)
        }
    }

    func stop() {
        guard state != .stopped else { return }

        // StatefulMacros' cancel action commits synchronously and invalidates late completions.
        cancel()
    }

    func playerDidFail(_ error: Error, from player: any MediaPlayer) {
        guard self.player === player, playbackItem != nil else { return }

        fail(error)
    }

    private func fail(_ error: Error) {
        guard state != .stopped, state != .error else { return }

        if let recovery = handoffRecovery {
            handoffRecovery = nil
            resolve(recovery.intent, using: recovery.player)
            commandError = L10n.unableToTransferPlayback
            return
        }
        if canReturnToLocalPlayback {
            returnToLocalPlayback()
            commandError = L10n.remotePlaybackFailed
            return
        }
        if canControlPlayback {
            intent = currentIntent()
            intent.configuration.startSeconds = observedSeconds
        }

        logger.error("Playback failed: \(error.localizedDescription)")
        core.send(\.error, error)
    }

    private func tearDown() {
        handoffRecovery = nil
        transferTask?.cancel()
        transferTask = nil
        resolutionID = UUID()
        resolutionTask = nil
        queueAdvanceTask = nil
        isAdvancingQueue = false
        playbackTransitions.reset()

        progressReporter.stop()
        discardUnstartedItem()
        hasReportedPlayback = false

        resetPlayback()
        player?.stop()

        sessionObservation = nil
        playbackItem?.mediaSession = nil
        playbackItem = nil

        if state == .stopped {
            player?.mediaSession = nil
            player = nil
            localPlayer = nil
        }
    }

    func ended(from player: any MediaPlayer) {
        guard self.player === player, canControlPlayback, !isSeeking, !item.isLiveStream else { return }
        guard let queue, userSession.user.data.configuration?.enableNextEpisodeAutoPlay == true else {
            stop()
            return
        }

        if let next = queue.nextItem {
            playNewItem(intent: next)
            return
        }

        guard queueAdvanceTask == nil else { return }

        isAdvancingQueue = true
        let id = resolutionID
        queueAdvanceTask = Task { [weak self] in
            do {
                let next = try await queue.next()
                guard !Task.isCancelled, let self, resolutionID == id, state != .stopped else { return }

                if let next, userSession.user.data.configuration?.enableNextEpisodeAutoPlay == true {
                    playNewItem(intent: next)
                } else {
                    stop()
                }
            } catch {
                guard !Task.isCancelled, let self, resolutionID == id, state != .stopped else { return }

                fail(error)
            }
        }
        .asAnyCancellable()
    }

    func setPlaybackRequestStatus(status: PlaybackRequestStatus) {
        guard state != .stopped, state != .error else { return }

        playbackRequestStatus = status

        guard playbackItem != nil, state == .preparing || state == .playback else { return }

        switch status {
        case .playing:
            player?.play()
        case .paused:
            player?.pause()
        }
    }

    func togglePlayPause() {
        guard canControlPlayback else { return }

        setPlaybackRequestStatus(status: playbackRequestStatus == .playing ? .paused : .playing)
    }

    func retry() {
        guard state == .error else { return }

        resolve(intent)
    }

    /// Native controls (such as AVKit PiP) can change the desired transport state.
    func playerDidRequestPlayback(_ status: PlaybackRequestStatus, from player: any MediaPlayer) {
        guard self.player === player, canControlPlayback else { return }

        playbackRequestStatus = status
    }

    func playerDidUpdate(_ snapshot: PlaybackState, from player: any MediaPlayer) {
        guard self.player === player, playbackItem != nil, state == .preparing || state == .playback else { return }

        if playbackState != snapshot {
            playbackState = snapshot
        }

        if state == .preparing, snapshot.isReady, resolutionTask == nil {
            beginPlayback()
        }
    }

    private func beginPlayback() {
        _beginPlayback()
    }

    @Function(\Action.Cases._beginPlayback)
    private func reportPlaybackStarted() {
        guard !hasReportedPlayback, let playbackItem else { return }

        handoffRecovery = nil
        hasReportedPlayback = true
        progressReporter.start(playbackItem)
    }

    private func observeSessionIfNeeded() {
        guard sessionObservation == nil else { return }

        sessionObservation = queue?.observe(self)
    }

    func playerDidUpdatePosition(_ position: Duration, from player: any MediaPlayer) {
        guard self.player === player, playbackItem != nil, state == .preparing || state == .playback else { return }

        timeline.observe(position)
        publishTimeline()
        playbackEventSubject.send(.positionChanged)
    }

    @discardableResult
    func seek(to position: Duration) -> Bool {
        guard canSeek else { return false }

        let origin = seconds
        let previousRequest = timeline.pending?.id

        timeline.requestSeek(to: position, duration: playbackState.duration ?? item.runtime)

        if let request = timeline.pending, request.id != previousRequest {
            playbackEventSubject.send(.seekRequested(request, origin: origin))
        }

        commandError = nil
        publishTimeline()
        scheduleSeek()

        return true
    }

    @discardableResult
    func seek(by offset: Duration) -> Bool {
        seek(to: seconds + offset)
    }

    private func scheduleSeek() {
        guard timeline.inFlight == nil, let player else { return }

        seekDispatchTask = Task { [weak self] in
            // Coalesce bursts without delaying the UI's response to each tap.
            do {
                try await Task.sleep(for: .milliseconds(80))
            } catch {
                return
            }

            guard let self, let request = timeline.beginSeek() else { return }
            guard canSeek else {
                playerDidCompleteSeek(request, position: nil, from: player)
                return
            }

            seekTimeoutTask = Task { [weak self] in
                do {
                    try await Task.sleep(for: .seconds(8))
                } catch {
                    return
                }

                guard let self, timeline.inFlight?.id == request.id else { return }

                player.cancelSeek()
                playerDidCompleteSeek(request, position: nil, from: player)
            }
            .asAnyCancellable()

            player.seek(request)
        }
        .asAnyCancellable()
    }

    func playerDidCompleteSeek(_ request: PlaybackTimeline.Seek, position: Duration?, from player: any MediaPlayer) {
        guard self.player === player,
              timeline.completeSeek(request.id, position: position) else { return }

        seekTimeoutTask = nil

        if position == nil, timeline.pending == nil {
            commandError = L10n.unableToSeek
        }

        publishTimeline()

        playbackEventSubject.send(.seekCompleted(request, position: position, hasPendingSeek: timeline.pending != nil))

        if timeline.pending != nil {
            scheduleSeek()
        }
    }

    private func publishTimeline() {
        if seconds != timeline.displayed {
            seconds = timeline.displayed
        }

        if observedSeconds != timeline.observed {
            observedSeconds = timeline.observed
        }

        if isSeeking != (timeline.pending != nil) {
            isSeeking = timeline.pending != nil
        }
    }

    private func resetPlayback() {
        seekDispatchTask = nil
        seekTimeoutTask = nil
        player?.cancelSeek()

        timeline.reset()
        playbackState = PlaybackState()
        publishTimeline()
    }

    private func discardUnstartedItem() {
        guard !hasReportedPlayback, let playbackItem else { return }

        let session = userSession

        Task {
            await MediaProgressReporter.discard(playbackItem, session: session)
        }
    }

    func setBitrate(bitrate: PlaybackBitrate) {
        guard canControlPlayback else { return }

        var intent = currentIntent()
        intent.configuration.requestedBitrate = bitrate
        resolve(intent)
    }

    func setResolution(resolution: PlaybackResolution) {
        guard canControlPlayback else { return }

        var intent = currentIntent()
        intent.configuration.maxResolution = resolution
        resolve(intent)
    }

    /// An item requests a new stream after changing its own playback configuration.
    func reload(_ item: MediaPlayerItem) {
        guard playbackItem === item, canControlPlayback else { return }

        resolve(item.resumingIntent(at: seconds))
    }
}

extension MediaSession {

    func sceneDidEnterBackground() {
        playbackTransitions.sceneDidEnterBackground()
    }

    func cancelBackgroundPause() {
        playbackTransitions.cancelBackgroundPause()
    }

    func startPictureInPicture() {
        playbackTransitions.startPictureInPicture()
    }

    func stopPictureInPicture() {
        playbackTransitions.stopPictureInPicture()
    }
}
