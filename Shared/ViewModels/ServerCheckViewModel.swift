//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI

@MainActor
@Stateful
final class ServerCheckViewModel: ViewModel {

    @CasePathable
    enum Action {
        case checkServer

        var transition: Transition {
            .to(.initial)
        }
    }

    enum Event {
        case connected
    }

    enum State {
        case error
        case initial
    }

    @Function(\Action.Cases.checkServer)
    private func _checkServer() async throws {

        let session = try requireUserSession()
        try await session.server.updateServerInfo()

        let request = Paths.getCurrentUser
        let response = try await send(request)

        session.user.data = response.value
        Container.shared.userSessionManager().refreshCurrentSession()
        events.send(.connected)
    }
}
