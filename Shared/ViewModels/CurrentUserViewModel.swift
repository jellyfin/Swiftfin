//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

final class CurrentUserViewModel: ViewModel, Stateful {

    // MARK: - Action

    enum Action: Equatable {
        case error(JellyfinAPIError)
        case getUser
    }

    // MARK: - State

    enum State: Hashable {
        case user
        case error(JellyfinAPIError)
        case loading
        case initial
    }

    // MARK: - Published Variables

    @Published
    var user: UserDto?
    @Published
    final var state: State = .initial

    // MARK: - Private Variables

    private var sessionTask: Task<Void, Never>?

    // MARK: - Stateful Conformance

    func respond(to action: Action) -> State {
        switch action {
        case .getUser:
            getUser()
            return .loading

        case let .error(error):
            return .error(error)
        }
    }

    // MARK: - Load Active User

    func getUser() {
        sessionTask?.cancel()

        sessionTask = Task {
            do {
                try await loadUser()
            } catch {
                await MainActor.run {
                    state = .error(JellyfinAPIError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Fetch Active User & Handle State

    private func loadUser() async throws {
        let currentUser = try await requestUser()

        await MainActor.run {
            user = currentUser
            state = .user
        }
    }

    // MARK: - Fetch Current User via API

    private func requestUser() async throws -> UserDto {
        let request = Paths.getCurrentUser
        let response = try await userSession.client.send(request)
        return response.value
    }
}
