//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

@MainActor
@Stateful
final class AddServerUserViewModel: ViewModel {

    // MARK: Actions

    @CasePathable
    enum Action {
        case cancel
        case create(username: String, password: String)

        var transition: Transition {
            switch self {
            case .cancel:
                .to(.initial)
            case .create:
                .to(.creating, then: .initial)
            }
        }
    }

    // MARK: Event

    enum Event {
        case created(UserDto)
        case error(JellyfinAPIError)
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case creating
    }

    private var userTask: AnyCancellable?

    // MARK: - Actions

    @Function(\Action.Cases.cancel)
    private func _cancel() async throws {
        userTask?.cancel()
    }

    @Function(\Action.Cases.create)
    private func _create(_ username: String, _ password: String) async throws {
        userTask?.cancel()

        let parameters = CreateUserByName(name: username, password: password)
        let request = Paths.createUserByName(parameters)
        let response = try await userSession.client.send(request)

        events.send(.created(response.value))
    }
}
