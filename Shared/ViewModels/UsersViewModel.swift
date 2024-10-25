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

final class UsersViewModel: ViewModel, Stateful {

    // MARK: - Action

    enum Action: Equatable {
        case getUsers
    }

    // MARK: - BackgroundState

    enum BackgroundState: Hashable {
        case gettingUsers
    }

    // MARK: - State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
    }

    @Published
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    final var users: [UserDto] = []

    @Published
    final var state: State = .initial

    private var userTask: AnyCancellable?

    // MARK: - Respond to Action

    func respond(to action: Action) -> State {
        switch action {
        case .getUsers:
            userTask?.cancel()

            backgroundStates.append(.gettingUsers)

            userTask = Task { [weak self] in
                do {
                    try await self?.loadUsers()
                    await MainActor.run {
                        self?.state = .content
                    }
                } catch {
                    guard let self else { return }
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }

                await MainActor.run {
                    self?.backgroundStates.remove(.gettingUsers)
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: - Load Users

    private func loadUsers() async throws {
        let request = Paths.getUsers()
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.users = response.value

            self.users.sort { x, y in
                let user0 = x
                let user1 = y
                return (user0.name ?? "") < (user1.name ?? "")
            }
        }
    }
}
