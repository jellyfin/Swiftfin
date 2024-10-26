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

final class ServerUserAdminViewModel: ViewModel, Eventful, Stateful, Identifiable {

    // MARK: Event

    enum Event {
        case error(JellyfinAPIError)
        case success
    }

    // MARK: BackgroundState

    enum BackgroundState {
        case updating
    }

    // MARK: Action

    enum Action: Equatable {
        case cancel
        case loadDetails
        case resetPassword
        case updatePassword(currentPassword: String?, newPassword: String)
        case updatePolicy(policy: UserPolicy)
    }

    // MARK: State

    enum State: Hashable {
        case error(JellyfinAPIError)
        case initial
    }

    // MARK: Published Values

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    @Published
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    final var state: State = .initial
    @Published
    private(set) var user: UserDto

    private var resetTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    // MARK: Initialize from UserDto

    init(user: UserDto) {
        self.user = user
    }

    // MARK: Respond

    func respond(to action: Action) -> State {
        switch action {
        case .cancel:
            resetTask?.cancel()

            return .initial
        case .resetPassword:
            if case .initial = state {
                return state
            }

            resetTask = Task {

                await MainActor.run {
                    _ = self.backgroundStates.append(.updating)
                }

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

                await MainActor.run {
                    _ = self.backgroundStates.remove(.updating)
                }
            }
            .asAnyCancellable()

            return .initial
        case .loadDetails:
            if case .initial = state {
                return state
            }

            resetTask = Task {
                do {
                    try await loadDetails()
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

            return .initial
        case let .updatePassword(currentPassword, newPassword):
            if case .initial = state {
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

            return .initial
        case let .updatePolicy(policy: policy):
            if case .initial = state {
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

            return .initial
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

    // MARK: - Load User

    private func loadDetails() async throws {
        guard let userId = user.id else { return }
        let request = Paths.getUserByID(userID: userId)
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.user = response.value
        }
    }
}
