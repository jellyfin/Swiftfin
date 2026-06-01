//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@MainActor
@Stateful
final class SendSessionMessageViewModel: ViewModel {

    @CasePathable
    enum Action {
        case send(header: String?, text: String, timeoutSeconds: Int)

        var transition: Transition {
            .to(.sending, then: .initial)
        }
    }

    enum Event {
        case sent
    }

    enum State: Hashable {
        case initial
        case sending
    }

    private let sessionID: String

    init(sessionID: String) {
        self.sessionID = sessionID

        super.init()
    }

    @Function(\Action.Cases.send)
    private func _send(_ header: String?, _ text: String, _ timeoutSeconds: Int) async throws {
        let command = MessageCommand(
            header: header?.nilIfBlank,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            timeoutMs: timeoutSeconds * 1000
        )
        let request = Paths.sendMessageCommand(sessionID: sessionID, command)

        try await userSession.client.send(request)

        events.send(.sent)
    }
}

private extension String {

    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmed.isEmpty ? nil : trimmed
    }
}
