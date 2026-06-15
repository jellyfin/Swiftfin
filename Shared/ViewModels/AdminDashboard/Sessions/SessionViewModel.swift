//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

@MainActor
@Stateful
final class SessionViewModel: ViewModel, Identifiable {

    @CasePathable
    enum Action {
        /// Start playing an item via a Remote Playback Session on another Jellyfin Client
        case remotePlaybackSession(
            command: PlayCommand,
            itemIDs: [String],
            startPositionTicks: Int?,
            mediaSourceID: String?,
            audioStreamIndex: Int?,
            subtitleStreamIndex: Int?,
            startIndex: Int?
        )
        /// Convenience helper to end a Remote Playback Session
        case stopReportPlaybackSession

        case sendMessage(MessageCommand)
        case sendPlaystateCommand(command: PlaystateCommand, seekPositionTicks: Int?)
        case sendGeneralCommand(GeneralCommandType)

        var transition: Transition {
            .background(.sending)
        }
    }

    enum BackgroundState {
        case sending
    }

    enum State {
        case initial
        case error
    }

    @Published
    var session: SessionInfoDto

    var id: String? {
        session.id
    }

    private var sessionCancellables = Set<AnyCancellable>()

    init(session: SessionInfoDto) {
        self.session = session
        super.init()
    }

    init(observing session: SessionInfoDto) {
        self.session = session
        super.init()

        Publishers.Merge(
            Notifications[.didChangeUserSession].publisher,
            Notifications[.applicationWillEnterForeground].publisher
        )
        .prepend(())
        .sink { [weak self] _ in
            Task { @MainActor in
                self?.observeSession()
            }
        }
        .store(in: &cancellables)
    }

    private func observeSession() {
        sessionCancellables.removeAll()

        $userSession.resolve(reset: .scope)

        guard let socket = userSession?.serverSocketManager else { return }

        socket
            .subscribe(.sessions, delay: .seconds(2), interval: .seconds(2))
            .store(in: &sessionCancellables)

        socket.events
            .compactMap { event -> [SessionInfoDto]? in
                guard case let .message(.sessionsMessage(msg)) = event else { return nil }
                return msg.data
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                Task { @MainActor in
                    guard let self else { return }
                    guard let updated = sessions.first(where: { $0.id == self.session.id }) else { return }
                    self.session = updated
                }
            }
            .store(in: &sessionCancellables)
    }

    // MARK: - Remote Playback Session

    @Function(\Action.Cases.remotePlaybackSession)
    private func _startRemoteSession(
        _ command: PlayCommand,
        _ itemIDs: [String],
        _ startPositionTicks: Int? = nil,
        _ mediaSourceID: String? = nil,
        _ audioStreamIndex: Int? = nil,
        _ subtitleStreamIndex: Int? = nil,
        _ startIndex: Int? = nil
    ) async throws {
        guard let id = session.id else { return }

        let request = Paths.play(
            sessionID: id,
            parameters: .init(
                playCommand: command,
                itemIDs: itemIDs,
                startPositionTicks: startPositionTicks,
                mediaSourceID: mediaSourceID,
                audioStreamIndex: audioStreamIndex,
                subtitleStreamIndex: subtitleStreamIndex,
                startIndex: startIndex
            )
        )
        try await send(request)
    }

    @Function(\Action.Cases.stopReportPlaybackSession)
    private func _stopRemoteSession() async throws {
        await self.sendPlaystateCommand(command: .stop, seekPositionTicks: nil)
    }

    // MARK: - Raw Session Commands

    @Function(\Action.Cases.sendMessage)
    private func _sendMessage(_ command: MessageCommand) async throws {
        guard let id = session.id else { return }

        let request = Paths.sendMessageCommand(sessionID: id, command)
        try await send(request)
    }

    @Function(\Action.Cases.sendPlaystateCommand)
    private func _sendPlaystateCommand(_ command: PlaystateCommand, _ seekPositionTicks: Int?) async throws {
        guard let id = session.id else { return }

        let request = Paths.sendPlaystateCommand(
            sessionID: id,
            command: command.rawValue,
            seekPositionTicks: seekPositionTicks
        )
        try await send(request)
    }

    @Function(\Action.Cases.sendGeneralCommand)
    private func _sendGeneralCommand(_ command: GeneralCommandType) async throws {
        guard let id = session.id else { return }

        let request = Paths.sendGeneralCommand(sessionID: id, command: command.rawValue)
        try await send(request)
    }
}
