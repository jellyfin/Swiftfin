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
        case sendMessage(MessageCommand)
        case sendPlaystateCommand(command: PlaystateCommand, seekPositionTicks: Int? = nil)
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

    init(session: SessionInfoDto) {
        self.session = session
        super.init()
    }

    @Function(\Action.Cases.sendMessage)
    private func _sendMessage(_ command: MessageCommand) async throws {
        guard let id = session.id else { return }

        let request = Paths.sendMessageCommand(sessionID: id, command)
        try await userSession.client.send(request)
    }

    @Function(\Action.Cases.sendPlaystateCommand)
    private func _sendPlaystateCommand(_ command: PlaystateCommand, _ seekPositionTicks: Int?) async throws {
        guard let id = session.id else { return }

        let request = Paths.sendPlaystateCommand(
            sessionID: id,
            command: command.rawValue,
            seekPositionTicks: seekPositionTicks
        )
        try await userSession.client.send(request)
    }

    @Function(\Action.Cases.sendGeneralCommand)
    private func _sendGeneralCommand(_ command: GeneralCommandType) async throws {
        guard let id = session.id else { return }

        let request = Paths.sendGeneralCommand(sessionID: id, command: command.rawValue)
        try await userSession.client.send(request)
    }
}
