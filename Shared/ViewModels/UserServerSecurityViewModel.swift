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

final class UserServerSecurityViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case load(userID: String)
        case userDetails(userID: String)
        case error(JellyfinAPIError)
    }

    // MARK: BackgroundState

    enum BackgroundStates: Hashable {
        case refresh
    }

    // MARK: State

    enum State: Hashable {
        case idle
        case error(JellyfinAPIError)
        case running
        case loaded(UserDto)
    }

    @Published
    final var state: State = .idle

    private var sessionTask: Task<Void, Never>?

    var userID: String?

    // MARK: Initializer

    init(userID: String) {
        self.userID = userID
    }

    // MARK: Stateful Conformance

    func respond(to action: Action) -> State {
        switch action {
        case let .error(error):
            return .error(error)
        default:
            performFunction(for: action)
            return .running
        }
    }

    // MARK: Session Management

    func performFunction(for action: Action) {
        sessionTask?.cancel()

        sessionTask = Task {
            do {
                switch action {
                case let .load(userID), let .userDetails(userID):
                    let user = try await sendRequest(for: userID)
                    await MainActor.run {
                        self.state = .loaded(user)
                    }

                case let .error(error):
                    await MainActor.run {
                        self.state = .error(error)
                    }
                }
            } catch is CancellationError {
                print("Active Sessions refresh was cancelled")
            } catch {
                await MainActor.run {
                    self.state = .error(JellyfinAPIError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: Network Request

    private func sendRequest(for userID: String) async throws -> UserDto {
        let request = Paths.getUserByID(userID: userID)
        let response = try await userSession.client.send(request)
        return response.value
    }
}
