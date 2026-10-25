//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import FactoryKit
import Foundation
import Get
import JellyfinAPI
import Observation

@MainActor
@Observable
final class JellyfinCastMediaPlayer: MediaPlayer {

    // The target client negotiates its own stream, direct play keeps the server from transcoding for this device.
    let playbackProfile = PlaybackProfile.local(.mpv)
    let playbackLocation = MediaPlaybackLocation.remote
    let supportedRates = 1.0 ... 1.0
    let sessionID: String?
    let displayTitle: String

    @ObservationIgnored
    weak var mediaSession: MediaSession?

    @ObservationIgnored
    private var userSession: UserSession?
    @ObservationIgnored
    private var baseItem: BaseItemDto?
    @ObservationIgnored
    private var commandTask: Task<Void, Never>?
    @ObservationIgnored
    private var sessionObservation: AnyCancellable?
    @ObservationIgnored
    private var progressTask: Task<Void, Never>?
    @ObservationIgnored
    private var loadTimeoutTask: Task<Void, Never>?
    private var isReady = false
    private var isPlaying = false
    private var receiverStopped = false
    private var handledEnd = false
    private var position: Duration = .zero
    private var suppressSyncUntil: Date = .distantPast

    init(session: SessionInfoDto) {
        self.sessionID = session.id
        self.displayTitle = session.deviceName ?? L10n.cast
    }

    isolated deinit {
        stop()
    }

    func load(_ item: MediaPlayerItem) {
        reset()

        guard let sessionID, let itemID = item.baseItem.id, let userSession = mediaSession?.userSession else {
            mediaSession?.playerDidFail(ErrorMessage(L10n.castConnectionFailed), from: self)
            return
        }

        self.userSession = userSession
        baseItem = item.baseItem
        receiverStopped = false
        position = item.baseItem.startSeconds ?? .zero

        let request = Paths.play(
            sessionID: sessionID,
            parameters: .init(
                playCommand: .playNow,
                itemIDs: [itemID],
                startPositionTicks: item.baseItem.isLiveStream ? nil : position.ticks,
                mediaSourceID: item.baseItem.isLiveStream ? nil : item.mediaSource.id,
                audioStreamIndex: item.selectedAudioStreamIndex,
                subtitleStreamIndex: item.selectedSubtitleStreamIndex ?? -1
            )
        )

        enqueue(request) { [weak self] error in
            guard let self, baseItem?.id == itemID else { return }

            if error != nil {
                mediaSession?.playerDidFail(ErrorMessage(L10n.remotePlaybackFailed), from: self)
            }
        }

        sessionObservation = Container.shared
            .userSessionManager()
            .$currentSession
            .map { session -> AnyPublisher<[SessionInfoDto], Never> in
                session?.serverSocketManager.sessions() ?? Combine.Empty<[SessionInfoDto], Never>().eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink { [weak self] sessions in
                Task { @MainActor in
                    guard let self else { return }

                    self.update(sessions.first { $0.id == self.sessionID })
                }
            }

        loadTimeoutTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(30)) } catch { return }
            guard let self, baseItem?.id == itemID, !isReady else { return }

            mediaSession?.playerDidFail(ErrorMessage(L10n.castConnectionFailed), from: self)
        }

        progressTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                self?.advancePosition()
            }
        }
    }

    func play() {
        guard isReady else { return }

        isPlaying = true
        send(.unpause)
    }

    func pause() {
        guard isReady else { return }

        isPlaying = false
        send(.pause)
    }

    func setRate(_ rate: Double) {}

    func stop() {
        let shouldStop = isReady && !receiverStopped
        let pendingItemID = !isReady && !receiverStopped ? baseItem?.id : nil

        reset()

        guard let sessionID, let userSession else { return }

        if shouldStop {
            enqueue(Paths.sendPlaystateCommand(sessionID: sessionID, command: PlaystateCommand.stop.rawValue))
        } else if let pendingItemID {
            Self.stopPendingLoad(pendingItemID, sessionID: sessionID, userSession: userSession)
        }
    }

    // A Play command can outlive dismissal, stop it only once the target reports that item.
    private static func stopPendingLoad(_ itemID: String, sessionID: String, userSession: UserSession) {
        Task {
            let deadline = ContinuousClock.now.advanced(by: .seconds(30))

            while ContinuousClock.now < deadline {
                if let target = try? await Self.session(sessionID, userSession: userSession),
                   target.nowPlayingItem?.id == itemID
                {
                    try? await userSession.send(Paths.sendPlaystateCommand(sessionID: sessionID, command: PlaystateCommand.stop.rawValue))
                    return
                }
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func stopForTransfer() async throws {
        guard isReady, !receiverStopped, let sessionID, let userSession else {
            stop()
            return
        }

        let previousCommand = commandTask
        reset()

        await previousCommand?.value

        do {
            try await userSession.send(Paths.sendPlaystateCommand(sessionID: sessionID, command: PlaystateCommand.stop.rawValue))
        } catch {
            throw ErrorMessage(L10n.unableToStopRemotePlayback)
        }
    }

    func seek(_ request: PlaybackTimeline.Seek) {
        guard isReady, let sessionID else {
            mediaSession?.playerDidCompleteSeek(request, position: nil, from: self)
            return
        }

        markLocalCommand()

        let seek = Paths.sendPlaystateCommand(
            sessionID: sessionID,
            command: PlaystateCommand.seek.rawValue,
            seekPositionTicks: request.target.ticks
        )

        enqueue(seek) { [weak self] error in
            guard let self else { return }

            if error == nil {
                position = request.target
            } else {
                mediaSession?.commandError = L10n.remoteCommandFailed
            }

            mediaSession?.playerDidCompleteSeek(request, position: error == nil ? request.target : nil, from: self)
        }
    }

    func cancelSeek() {}

    private func reset() {
        sessionObservation = nil
        progressTask?.cancel()
        progressTask = nil
        loadTimeoutTask?.cancel()
        loadTimeoutTask = nil
        baseItem = nil
        isReady = false
        isPlaying = false
        handledEnd = false
        suppressSyncUntil = .distantPast
    }

    private func send(_ command: PlaystateCommand) {
        guard let sessionID else { return }

        markLocalCommand()
        publishState()

        enqueue(Paths.sendPlaystateCommand(sessionID: sessionID, command: command.rawValue)) { [weak self] error in
            guard let self, error != nil else { return }

            suppressSyncUntil = .distantPast
            mediaSession?.commandError = L10n.remoteCommandFailed
        }
    }

    // Commands run in order so a stop for the previous item never lands after the next play.
    private func enqueue(_ request: Request<Void>, completion: (@MainActor (Error?) -> Void)? = nil) {
        guard let userSession else { return }

        let previousCommand = commandTask

        commandTask = Task { [weak self] in
            await previousCommand?.value

            var failure: Error?
            do {
                try await userSession.send(request)
            } catch {
                failure = error
            }

            completion?(failure)
            await self?.refreshState()
        }
    }

    private func markLocalCommand() {
        suppressSyncUntil = .now.addingTimeInterval(5)
    }

    private static func session(_ sessionID: String, userSession: UserSession) async throws -> SessionInfoDto? {
        let response = try await userSession.send(Paths.getSessions(parameters: .init()))
        defer { withExtendedLifetime(response) {} }

        return response.value.first { $0.id == sessionID }
    }

    // The sessions socket is event-driven and not sent to every user, so state is also fetched after each command.
    private func refreshState() async {
        guard let sessionID, let userSession, baseItem != nil,
              let target = try? await Self.session(sessionID, userSession: userSession) else { return }

        update(target)
    }

    private func advancePosition() {
        guard isReady, isPlaying, let baseItem else { return }

        position += .seconds(1)
        if let runtime = baseItem.runtime, !baseItem.isLiveStream {
            position = min(position, runtime)
        }

        mediaSession?.playerDidUpdatePosition(position, from: self)
    }

    private func publishState() {
        guard let mediaSession, let baseItem else { return }

        mediaSession.playerDidUpdate(
            PlaybackState(
                isReady: isReady,
                isPlaying: isPlaying,
                isSeekable: !baseItem.isLiveStream,
                duration: baseItem.isLiveStream ? nil : baseItem.runtime
            ),
            from: self
        )
    }

    private func update(_ target: SessionInfoDto?) {
        guard let target, let mediaSession, mediaSession.player === self, let baseItem else { return }
        guard target.isPlaying(item: baseItem) else {
            guard isReady, !handledEnd else { return }

            handledEnd = true
            receiverStopped = true

            // Clients clear their now playing item when an item finishes, so only a stop near the runtime counts as finished.
            if target.nowPlayingItem == nil, let runtime = baseItem.runtime, !baseItem.isLiveStream,
               runtime - position < .seconds(20)
            {
                mediaSession.ended(from: self)
            } else {
                mediaSession.setPlaybackRequestStatus(status: .paused)
                mediaSession.returnToLocalPlayback()
            }
            return
        }

        let wasReady = isReady
        if !isReady {
            isReady = true
            loadTimeoutTask?.cancel()
            loadTimeoutTask = nil
        }

        if Date.now >= suppressSyncUntil, let playState = target.playState {
            isPlaying = playState.isPaused != true
            if let reported = playState.position {
                position = reported
            }
        }

        publishState()
        mediaSession.playerDidUpdatePosition(position, from: self)

        if !wasReady {
            if mediaSession.playbackRequestStatus == .paused, isPlaying {
                pause()
            } else if mediaSession.playbackRequestStatus == .playing, !isPlaying {
                play()
            }
        } else if Date.now >= suppressSyncUntil {
            mediaSession.playerDidRequestPlayback(isPlaying ? .playing : .paused, from: self)
        }
    }
}
