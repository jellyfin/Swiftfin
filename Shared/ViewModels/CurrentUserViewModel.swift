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

    // MARK: Action

    enum Action: Equatable {
        case error(JellyfinAPIError)
        case fetchUser
    }

    // MARK: State

    enum State: Hashable {
        case user
        case error(JellyfinAPIError)
        case loading
        case initial
    }

    @Published
    var user: UserDto?
    @Published
    final var state: State = .initial

    private var sessionTask: Task<Void, Never>?

    // MARK: Stateful Conformance

    func respond(to action: Action) -> State {
        switch action {
        case .fetchUser:
            fetchUser()
            return .loading

        case let .error(error):
            return .error(error)
        }
    }

    // MARK: Session Management

    func fetchUser() {
        sessionTask?.cancel()

        sessionTask = Task {
            do {
                try await self.performUserLoading()
            } catch {
                await MainActor.run {
                    self.state = .error(JellyfinAPIError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: Fetch the Current User

    private func performUserLoading() async throws {
        let currentUser = try await fetchCurrentUser()

        await MainActor.run {
            self.user = currentUser
            self.state = .user
        }
    }

    // MARK: API Call the Current User

    private func fetchCurrentUser() async throws -> UserDto {
        let request = Paths.getCurrentUser
        let response = try await userSession.client.send(request)

        return response.value
    }
}
