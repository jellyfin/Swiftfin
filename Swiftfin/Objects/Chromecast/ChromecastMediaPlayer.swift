//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import Foundation
@preconcurrency import GoogleCast
import Observation

@MainActor
@Observable
final class ChromecastMediaPlayer: NSObject, MediaPlayer {

    let playbackProfile = PlaybackProfile.chromecast
    let playbackLocation = MediaPlaybackLocation.remote
    let supportedRates = 0.5 ... 2.0
    let session: GCKCastSession
    var displayTitle: String {
        session.device.friendlyName ?? L10n.cast
    }

    @ObservationIgnored
    weak var mediaSession: MediaSession?

    private enum Command {
        case load
        case seek(PlaybackTimeline.Seek)
        case transport
        case rate
        case status
        case stopForTransfer
    }

    @ObservationIgnored
    private var client: GCKRemoteMediaClient?
    @ObservationIgnored
    private var commands: [ObjectIdentifier: (request: GCKRequest, command: Command)] = [:]
    @ObservationIgnored
    private var progressTask: Task<Void, Never>?
    @ObservationIgnored
    private var loadTimeoutTask: Task<Void, Never>?
    @ObservationIgnored
    private var transferTimeoutTask: Task<Void, Never>?
    @ObservationIgnored
    private var transferContinuation: CheckedContinuation<Void, Error>?
    private var receiverStopped = false
    private var playbackID: String?
    private var isReady = false
    private var loadAcknowledged = false
    private var awaitingStatus = false
    private var isSuspended = false
    private var handledEnd = false

    init(session: GCKCastSession) {
        self.session = session
        super.init()
    }

    isolated deinit {
        stop()
    }

    func load(_ item: MediaPlayerItem) {
        stop()

        guard session.connectionState == .connected, let client = session.remoteMediaClient else {
            mediaSession?.playerDidFail(ErrorMessage(L10n.castConnectionFailed), from: self)
            return
        }

        self.client = client
        receiverStopped = false
        client.add(self)

        let playbackID = UUID().uuidString
        self.playbackID = playbackID

        let metadata = GCKMediaMetadata(metadataType: item.baseItem.type == .episode ? .tvShow : .movie)
        metadata.setString(item.baseItem.displayTitle, forKey: kGCKMetadataKeyTitle)

        let information = GCKMediaInformationBuilder(contentURL: item.url)
        information.contentType = "application/x-mpegURL"
        information.streamType = item.baseItem.isLiveStream ? .live : .buffered
        information.streamDuration = item.baseItem.isLiveStream ? .infinity : (item.baseItem.runtime?.seconds ?? 0)
        information.metadata = metadata
        information.customData = ["playbackID": playbackID]

        let load = GCKMediaLoadRequestDataBuilder()
        load.mediaInformation = information.build()
        load.autoplay = NSNumber(value: mediaSession?.playbackRequestStatus == .playing)
        load.playbackRate = Float(mediaSession?.effectiveRate ?? 1)

        if !item.baseItem.isLiveStream {
            load.startTime = item.baseItem.startSeconds?.seconds ?? 0
        }

        track(client.loadMedia(with: load.build()), as: .load)

        guard self.playbackID == playbackID else { return }

        loadTimeoutTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(30)) } catch { return }
            guard let self, self.playbackID == playbackID, !isReady else { return }

            mediaSession?.playerDidFail(ErrorMessage(L10n.castConnectionFailed), from: self)
        }

        progressTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                self?.publishPosition()
                if self?.client?.mediaStatus?.playerState == .idle {
                    self?.update(self?.client?.mediaStatus)
                }
            }
        }
    }

    private func owns(_ status: GCKMediaStatus?) -> Bool {
        guard let playbackID else { return false }

        return Self.owns(status, playbackID: playbackID)
    }

    private static func owns(_ status: GCKMediaStatus?, playbackID: String) -> Bool {
        guard let customData = status?.mediaInformation?.customData as? [String: Any] else { return false }

        return customData["playbackID"] as? String == playbackID
    }

    private var canSendCommands: Bool {
        !isSuspended && !awaitingStatus && client?.connected == true && owns(client?.mediaStatus)
    }

    func play() {
        guard canSendCommands, let client else { return }

        track(client.play(), as: .transport)
    }

    func pause() {
        guard canSendCommands, let client else { return }

        track(client.pause(), as: .transport)
    }

    func setRate(_ rate: Double) {
        guard isReady, canSendCommands, let client else { return }

        track(client.setPlaybackRate(Float(min(max(rate, supportedRates.lowerBound), supportedRates.upperBound))), as: .rate)
    }

    func stop() {
        let shouldStop = !receiverStopped && owns(client?.mediaStatus)
        let pendingLoadID = !receiverStopped && !isReady ? playbackID : nil
        let continuation = transferContinuation

        transferContinuation = nil
        transferTimeoutTask?.cancel()
        transferTimeoutTask = nil

        let previousClient = client

        client?.remove(self)
        client = nil
        playbackID = nil
        isReady = false
        loadAcknowledged = false
        awaitingStatus = false
        isSuspended = false
        handledEnd = false
        progressTask?.cancel()
        progressTask = nil
        loadTimeoutTask?.cancel()
        loadTimeoutTask = nil

        let requests = commands.values.map(\.request)
        commands.removeAll()

        for request in requests {
            request.delegate = nil
            request.cancel()
        }

        if shouldStop, previousClient?.connected == true {
            previousClient?.stop()
        } else if let pendingLoadID, let previousClient {
            Self.stopPendingLoad(pendingLoadID, on: previousClient)
        }

        continuation?.resume(throwing: CancellationError())
    }

    /// An in-flight LOAD can outlive dismissal. Retain only its client and identifier
    /// until it appears, so cleanup never sends STOP against another sender's media.
    private static func stopPendingLoad(_ playbackID: String, on client: GCKRemoteMediaClient) {
        Task {
            let deadline = ContinuousClock.now.advanced(by: .seconds(30))

            while ContinuousClock.now < deadline {
                if client.connected, owns(client.mediaStatus, playbackID: playbackID) {
                    client.stop()
                    return
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    func stopForTransfer() async throws {
        guard playbackID != nil, !receiverStopped else {
            stop()
            return
        }
        guard let client, client.connected else {
            stop()
            throw ErrorMessage(L10n.castConnectionFailed)
        }
        guard owns(client.mediaStatus) || !isReady else {
            stop()
            return
        }

        try await withTaskCancellationHandler {
            try Task.checkCancellation()

            try await withCheckedThrowingContinuation { continuation in
                transferContinuation = continuation
                transferTimeoutTask = Task { [weak self] in
                    do { try await Task.sleep(for: .seconds(5)) } catch { return }

                    self?.finishTransfer(error: ErrorMessage(L10n.unableToStopRemotePlayback))
                }

                stopOwnedMediaForTransfer()
            }
        } onCancel: {
            Task { @MainActor [weak self] in self?.finishTransfer(error: CancellationError()) }
        }
    }

    private func stopOwnedMediaForTransfer() {
        guard transferContinuation != nil, let client, owns(client.mediaStatus),
              !commands.values.contains(where: {
                  if case .stopForTransfer = $0.command {
                      true
                  } else {
                      false
                  }
              }) else { return }

        track(client.stop(), as: .stopForTransfer)
    }

    private func finishTransfer(error: Error?) {
        guard let continuation = transferContinuation else { return }

        transferContinuation = nil
        receiverStopped = receiverStopped || error == nil
        stop()

        if let error {
            continuation.resume(throwing: error)
        } else {
            continuation.resume()
        }
    }

    func sessionEnded(receiverStopped: Bool) {
        self.receiverStopped = receiverStopped
    }

    func seek(_ request: PlaybackTimeline.Seek) {
        guard isReady, canSendCommands, let client else {
            mediaSession?.playerDidCompleteSeek(request, position: nil, from: self)
            return
        }

        let options = GCKMediaSeekOptions()

        options.interval = request.target.seconds
        options.relative = false
        options.resumeState = .unchanged

        track(client.seek(with: options), as: .seek(request))
    }

    func cancelSeek() {
        let seeks = commands.filter {
            if case .seek = $0.value.command {
                true
            } else {
                false
            }
        }

        for (key, pending) in seeks {
            commands.removeValue(forKey: key)
            pending.request.delegate = nil
            pending.request.cancel()
        }
    }

    func connectionSuspended() {
        publishPosition()
        isSuspended = true
        cancelSeek()
        mediaSession?.playerDidUpdate(PlaybackState(isBuffering: true), from: self)
    }

    func connectionResumed() {
        client?.remove(self)
        client = session.remoteMediaClient
        client?.add(self)
        isSuspended = false
        awaitingStatus = true

        // Status, rather than another LOAD, determines where the receiver continued playing.
        guard let client else {
            mediaSession?.playerDidFail(ErrorMessage(L10n.castConnectionFailed), from: self)
            return
        }

        track(client.requestStatus(), as: .status)
    }

    private func track(_ request: GCKRequest, as command: Command) {
        commands[ObjectIdentifier(request)] = (request, command)
        request.delegate = self

        if let error = request.error {
            self.request(request, didFailWithError: error)
        }
    }

    private func publishPosition() {
        guard isReady, canSendCommands, let position = client?.approximateStreamPosition(), position.isFinite else { return }

        mediaSession?.playerDidUpdatePosition(.seconds(position), from: self)
    }

    private func update(_ status: GCKMediaStatus?) {
        guard !isSuspended, !awaitingStatus, let status, let mediaSession, mediaSession.player === self else { return }
        guard owns(status) else {
            // Another sender replaced our media. Do not stop or take control of its session.
            if isReady {
                mediaSession.setPlaybackRequestStatus(status: .paused)
                mediaSession.returnToLocalPlayback()
            }
            return
        }

        let wasReady = isReady
        let isActive = status.playerState == .playing || status.playerState == .paused || status.playerState == .buffering
        if isActive, loadAcknowledged {
            isReady = true
            loadTimeoutTask?.cancel()
            loadTimeoutTask = nil
        }
        let duration = status.mediaInformation?.streamDuration

        mediaSession.playerDidUpdate(
            PlaybackState(
                isReady: isReady,
                isPlaying: status.playerState == .playing,
                isSeekable: status.isMediaCommandSupported(kGCKMediaCommandSeek),
                duration: duration.flatMap { $0.isFinite && $0 > 0 ? .seconds($0) : nil },
                isBuffering: status.playerState == .buffering || status.playerState == .loading
            ),
            from: self
        )

        publishPosition()

        guard mediaSession.player === self else { return }

        if !wasReady, isReady {
            // Pause/play may have changed while the receiver was loading.
            if mediaSession.playbackRequestStatus == .paused, status.playerState != .paused {
                pause()
            }

            if mediaSession.playbackRequestStatus == .playing, status.playerState == .paused {
                play()
            }

            setRate(mediaSession.effectiveRate)
        } else if !commands.values.contains(where: {
            if case .transport = $0.command {
                true
            } else {
                false
            }
        }) {
            if status.playerState == .playing {
                mediaSession.playerDidRequestPlayback(.playing, from: self)
            }

            if status.playerState == .paused {
                mediaSession.playerDidRequestPlayback(.paused, from: self)
            }
        }
        guard status.playerState == .idle, !handledEnd else { return }

        handledEnd = true

        switch status.idleReason {
        case .finished:
            // A seek completion may still be pending when the receiver reports idle.
            // Let the next status poll retry the end event after the timeline settles.
            handledEnd = mediaSession.canControlPlayback && !mediaSession.isSeeking
            if handledEnd {
                mediaSession.ended(from: self)
            }

        case .error:
            mediaSession.playerDidFail(ErrorMessage(L10n.remotePlaybackFailed), from: self)

        case .cancelled, .interrupted:
            mediaSession.setPlaybackRequestStatus(status: .paused)
            mediaSession.returnToLocalPlayback()

        default:
            handledEnd = false
        }
    }
}

// Google Cast delivers delegate callbacks on the main thread.
extension ChromecastMediaPlayer: @preconcurrency GCKRemoteMediaClientListener, @preconcurrency GCKRequestDelegate {

    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        guard self.client === client else { return }

        awaitingStatus = false

        if transferContinuation != nil {
            stopOwnedMediaForTransfer()
            return
        }

        update(mediaStatus)
    }

    func requestDidComplete(_ request: GCKRequest) {
        guard let pending = commands.removeValue(forKey: ObjectIdentifier(request)) else { return }

        request.delegate = nil
        switch pending.command {
        case .stopForTransfer:
            finishTransfer(error: nil)
            return

        case let .seek(seek):
            // Use the receiver's landing position, never assume it accepted the exact target.
            let position = owns(client?.mediaStatus) ? client?.mediaStatus?.streamPosition : nil
            mediaSession?.playerDidCompleteSeek(seek, position: position.flatMap { $0.isFinite ? .seconds($0) : nil }, from: self)

        case .load:
            loadAcknowledged = true
            stopOwnedMediaForTransfer()

        case .status:
            awaitingStatus = false

        case .transport, .rate:
            break
        }
        update(client?.mediaStatus)
    }

    func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        failed(request)
    }

    func request(_ request: GCKRequest, didAbortWith abortReason: GCKRequestAbortReason) {
        failed(request)
    }

    private func failed(_ request: GCKRequest) {
        guard let pending = commands.removeValue(forKey: ObjectIdentifier(request)) else { return }

        request.delegate = nil
        switch pending.command {
        case .stopForTransfer:
            finishTransfer(error: ErrorMessage(L10n.unableToStopRemotePlayback))

        case .load:
            if transferContinuation != nil {
                finishTransfer(error: ErrorMessage(L10n.unableToStopRemotePlayback))
            } else {
                mediaSession?.playerDidFail(ErrorMessage(L10n.remotePlaybackFailed), from: self)
            }

        case let .seek(seek):
            mediaSession?.playerDidCompleteSeek(seek, position: nil, from: self)

        case .transport, .rate:
            mediaSession?.commandError = L10n.remoteCommandFailed
            update(client?.mediaStatus)

        case .status:
            mediaSession?.playerDidFail(ErrorMessage(L10n.castConnectionFailed), from: self)
        }
    }
}
#endif
