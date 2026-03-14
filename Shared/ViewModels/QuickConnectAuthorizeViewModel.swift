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
final class QuickConnectAuthorizeViewModel: ViewModel {

    @CasePathable
    enum Action {
        case authorize(code: String)
        case cancel

        var transition: Transition {
            switch self {
            case .authorize: .loop(.authorizing)
            case .cancel: .to(.initial)
            }
        }
    }

    enum Event {
        case authorized
        case error
    }

    enum State {
        case authorizing
        case initial
    }

    let user: UserDto

    init(user: UserDto) {
        self.user = user
        super.init()
    }

    @Function(\Action.Cases.authorize)
    private func _authorize(_ code: String) async throws {
        guard let userID = user.id else {
            logger.critical("User ID is nil")
            throw ErrorMessage(L10n.unknownError)
        }

        let request = Paths.authorizeQuickConnect(code: code, userID: userID)
        let response = try await userSession.client.send(request)

        let decoder = JSONDecoder()
        let isAuthorized = (try? decoder.decode(Bool.self, from: response.value)) ?? false

        guard isAuthorized else {
            throw ErrorMessage("Authorization unsuccessful")
        }

        events.send(.authorized)
    }
}
