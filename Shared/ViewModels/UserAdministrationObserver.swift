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

final class UserAdministrationObserver: ViewModel, Eventful, Stateful, Identifiable {

    // MARK: Event

    enum Event {
        case error(JellyfinAPIError)
        case success
    }

    // MARK: Action

    enum Action: Equatable {
        case cancel
        case resetPassword
        case updatePassword(currentPassword: String?, newPassword: String)
        case updatePolicy(policy: UserPolicy)
    }

    // MARK: State

    enum State: Hashable {
        case error(JellyfinAPIError)
        case initial
        case updating
    }

    // MARK: Published Values

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    @Published
    final var state: State = .initial
    @Published
    private(set) var user: UserDto

    private var resetTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    var id: String? { user.id }

    init(user: UserDto) {
        self.user = user
    }

    func respond(to action: Action) -> State {
        switch action {
        case .cancel:
            resetTask?.cancel()

            return .initial
        case .resetPassword:
            if case .updating = state {
                return state
            }

            resetTask = Task {
                do {
                    try await resetPassword()
                    await MainActor.run {
                        self.state = .initial
                        self.eventSubject.send(.success)
                    }
                } catch {
                    await MainActor.run {
                        let jellyfinError = JellyfinAPIError(error.localizedDescription)
                        self.state = .error(jellyfinError)
                        self.eventSubject.send(.error(jellyfinError))
                    }
                }
            }
            .asAnyCancellable()

            return .updating
        case let .updatePassword(currentPassword, newPassword):
            if case .updating = state {
                return state
            }

            resetTask = Task {
                do {
                    try await updatePassword(
                        currentPw: currentPassword,
                        newPw: newPassword
                    )
                    await MainActor.run {
                        self.state = .initial
                        self.eventSubject.send(.success)
                    }
                } catch {
                    await MainActor.run {
                        let jellyfinError = JellyfinAPIError(error.localizedDescription)
                        self.state = .error(jellyfinError)
                        self.eventSubject.send(.error(jellyfinError))
                    }
                }
            }
            .asAnyCancellable()

            return .updating
        case let .updatePolicy(policy: policy):
            if case .updating = state {
                return state
            }

            resetTask = Task {
                do {
                    try await updatePolicy(policy: policy)
                    await MainActor.run {
                        self.state = .initial
                        self.eventSubject.send(.success)
                    }
                } catch {
                    await MainActor.run {
                        let jellyfinError = JellyfinAPIError(error.localizedDescription)
                        self.state = .error(jellyfinError)
                        self.eventSubject.send(.error(jellyfinError))
                    }
                }
            }
            .asAnyCancellable()

            return .updating
        }
    }

    // MARK: - Reset Password

    private func resetPassword() async throws {
        guard let userId = user.id else { return }
        let parameters = UpdateUserPassword(isResetPassword: true)
        let updateRequest = Paths.updateUserPassword(userID: userId, parameters)
        try await userSession.client.send(updateRequest)

        await MainActor.run {
            self.user.hasPassword = false
        }
    }

    // MARK: - Update Password

    private func updatePassword(currentPw: String? = nil, newPw: String) async throws {
        guard let userId = user.id else { return }
        let parameters = UpdateUserPassword(
            currentPw: currentPw,
            newPw: newPw
        )
        let updateRequest = Paths.updateUserPassword(userID: userId, parameters)
        try await userSession.client.send(updateRequest)

        await MainActor.run {
            self.user.hasPassword = (newPw != "")
        }
    }

    // MARK: - Update User Policy

    private func updatePolicy(policy: UserPolicy) async throws {
        guard let userId = user.id else { return }
        let updateRequest = Paths.updateUserPolicy(userID: userId, policy)
        try await userSession.client.send(updateRequest)

        await MainActor.run {
            self.user.policy = policy
        }
    }

    // MARK: - Update User Configuration

    private func updatePolicy(configuration: UserConfiguration) async throws {
        guard let userId = user.id else { return }
        let updateRequest = Paths.updateUserConfiguration(userID: userId, configuration)
        try await userSession.client.send(updateRequest)

        await MainActor.run {
            self.user.configuration = configuration
        }
    }
}
