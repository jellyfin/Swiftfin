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
final class ResetUserPasswordViewModel: ViewModel {

    @CasePathable
    enum Action {
        case cancel
        case reset(current: String, new: String)

        var transition: Transition {
            switch self {
            case .cancel:
                .to(.initial)
            case .reset:
                .to(.resetting, then: .initial)
            }
        }
    }

    enum Event {
        case error
        case success
    }

    enum State {
        case initial
        case resetting
    }

    let userID: String

    init(userID: String) {
        self.userID = userID
    }

    @Function(\Action.Cases.reset)
    private func _reset(_ current: String, _ new: String) async throws {
        let body = UpdateUserPassword(currentPw: current, newPw: new)
        let request = Paths.updateUserPassword(userID: userID, body)

        try await send(request)

        events.send(.success)
    }
}
