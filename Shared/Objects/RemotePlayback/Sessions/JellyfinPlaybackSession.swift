//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

@MainActor
final class JellyfinPlaybackSession: ViewModel, RemotePlaybackSession {

    let route: RemotePlaybackRoute = .jellyfin
    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)

    let deviceName: String?

    weak var manager: MediaPlayerManager?

    private let sessionID: String
    private var castItemID: String?
    private var pollTask: Task<Void, Never>?
    private var startTimeoutTask: Task<Void, Never>?
    private var hasStartedRemote = false

    init(session: SessionInfoDto) {
        self.sessionID = session.id ?? ""
        self.deviceName = session.deviceName ?? session.client
        super.init()
    }

    func connect(startingAt seconds: Duration) async throws {
        guard let itemID = manager?.item.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        castItemID = itemID

        let playbackItem = manager?.playbackItem

        var parameters = Paths.PlayParameters(
            playCommand: .playNow,
            itemIDs: [itemID]
        )
        parameters.startPositionTicks = seconds.ticks
        parameters.mediaSourceID = playbackItem?.mediaSource.id
        parameters.audioStreamIndex = playbackItem?.selectedAudioStreamIndex
        parameters.subtitleStreamIndex = playbackItem?.selectedSubtitleStreamIndex

        logger.info("⏱ jellyfin connect: startingAt=\(seconds.seconds)s sentTicks=\(parameters.startPositionTicks ?? -1)")

        let request = Paths.play(sessionID: sessionID, parameters: parameters)
        try await userSession.client.send(request)

        hasStartedRemote = false
        startPolling()
        startStartTimeout()
    }

    func disconnect() {
        pollTask?.cancel()
        pollTask = nil
        startTimeoutTask?.cancel()
        startTimeoutTask = nil
        send(.stop)
    }

    func play() {
        send(.unpause)
    }

    func pause() {
        send(.pause)
    }

    func stop() {
        send(.stop)
    }

    func jumpForward(_ seconds: Duration) {
        seek(to: (manager?.seconds ?? .zero) + seconds)
    }

    func jumpBackward(_ seconds: Duration) {
        seek(to: max(.zero, (manager?.seconds ?? .zero) - seconds))
    }

    func setRate(_ rate: Float) {}

    func setSeconds(_ seconds: Duration, completion: ((Bool) -> Void)?) {
        seek(to: seconds)
        completion?(true)
    }

    private func seek(to seconds: Duration) {
        manager?.seconds = seconds
        send(.seek, seekTicks: seconds.ticks)
    }

    private func send(_ command: PlaystateCommand, seekTicks: Int? = nil) {
        let request = Paths.sendPlaystateCommand(
            sessionID: sessionID,
            command: command.rawValue,
            seekPositionTicks: seekTicks
        )

        Task {
            try? await userSession.client.send(request)
        }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.poll()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    private func startStartTimeout() {
        startTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(30))
            guard let self, !self.hasStartedRemote else { return }
            self.manager?.remote.end(route: .jellyfin)
        }
    }

    private func poll() async {
        var parameters = Paths.GetSessionsParameters()
        parameters.activeWithinSeconds = 60

        guard let response = try? await userSession.client.send(Paths.getSessions(parameters: parameters)),
              let session = response.value.first(where: { $0.id == sessionID })
        else { return }

        // Only sync from the remote while it's playing OUR item — otherwise the
        // device's own position/state would stomp ours, jumping the scrubber and
        // returning local playback to the wrong place.
        let isPlayingOurItem = session.nowPlayingItem?.id == castItemID

        if isPlayingOurItem {
            hasStartedRemote = true
            startTimeoutTask?.cancel()

            if let positionTicks = session.playState?.positionTicks {
                manager?.seconds = .ticks(positionTicks)
            }

            if let isPaused = session.playState?.isPaused {
                await manager?.setPlaybackRequestStatus(status: isPaused ? .paused : .playing)
            }
        } else if hasStartedRemote {
            manager?.remote.end(route: .jellyfin)
        }
    }
}
