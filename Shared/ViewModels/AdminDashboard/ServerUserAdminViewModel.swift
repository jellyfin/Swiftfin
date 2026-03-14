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
import OrderedCollections

final class ServerUserAdminViewModel: ViewModel, Eventful, Stateful, Identifiable {

    // MARK: - Event

    enum Event {
        case error(ErrorMessage)
        case updated
    }

    // MARK: - Action

    enum Action: Equatable {
        case cancel
        case refresh
        case loadLibraries(isHidden: Bool? = false)
        case updatePolicy(UserPolicy)
        case updateConfiguration(UserConfiguration)
        case updateUsername(String)
    }

    // MARK: - Background State

    enum BackgroundState: Hashable {
        case updating
        case refreshing
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case content
        case error(ErrorMessage)
    }

    // MARK: - Published Values

    @Published
    var state: State = .initial
    @Published
    var backgroundStates: Set<BackgroundState> = []

    @Published
    private(set) var user: UserDto

    @Published
    var libraries: [BaseItemDto] = []

    private var userTaskCancellable: AnyCancellable?
    private var eventSubject = PassthroughSubject<Event, Never>()

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Initializer

    init(user: UserDto) {
        self.user = user
        super.init()

        Notifications[.didChangeUserProfile]
            .publisher
            .sink { userID in
                guard userID == self.user.id else { return }

                Task {
                    await self.send(.refresh)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Respond

    func respond(to action: Action) -> State {
        switch action {
        case .cancel:
            return .initial

        case .refresh:
            userTaskCancellable?.cancel()

            userTaskCancellable = Task {
                do {
                    await MainActor.run {
                        _ = backgroundStates.insert(.refreshing)
                    }

                    try await loadDetails()

                    await MainActor.run {
                        state = .content
                        _ = backgroundStates.remove(.refreshing)
                    }
                } catch {
                    await MainActor.run {
                        state = .error(.init(error.localizedDescription))
                        eventSubject.send(.error(.init(error.localizedDescription)))
                        _ = backgroundStates.remove(.refreshing)
                    }
                }
            }
            .asAnyCancellable()

            return state

        case let .loadLibraries(isHidden):
            userTaskCancellable?.cancel()

            userTaskCancellable = Task {
                do {
                    await MainActor.run {
                        _ = backgroundStates.insert(.refreshing)
                    }

                    try await loadLibraries(isHidden: isHidden)

                    await MainActor.run {
                        state = .content
                        _ = backgroundStates.remove(.refreshing)
                    }
                } catch {
                    await MainActor.run {
                        state = .error(.init(error.localizedDescription))
                        eventSubject.send(.error(.init(error.localizedDescription)))
                        _ = backgroundStates.remove(.refreshing)
                    }
                }
            }
            .asAnyCancellable()

            return state

        case let .updatePolicy(policy):
            userTaskCancellable?.cancel()

            userTaskCancellable = Task {
                do {
                    await MainActor.run {
                        _ = backgroundStates.insert(.updating)
                    }

                    try await updatePolicy(policy: policy)

                    await MainActor.run {
                        state = .content
                        eventSubject.send(.updated)
                        _ = backgroundStates.remove(.updating)
                    }
                } catch {
                    await MainActor.run {
                        state = .error(.init(error.localizedDescription))
                        eventSubject.send(.error(.init(error.localizedDescription)))
                        _ = backgroundStates.remove(.updating)
                    }
                }
            }
            .asAnyCancellable()

            return state

        case let .updateConfiguration(configuration):
            userTaskCancellable?.cancel()

            userTaskCancellable = Task {
                do {
                    await MainActor.run {
                        _ = backgroundStates.insert(.updating)
                    }

                    try await updateConfiguration(configuration: configuration)

                    await MainActor.run {
                        state = .content
                        eventSubject.send(.updated)
                        _ = backgroundStates.remove(.updating)
                    }
                } catch {
                    await MainActor.run {
                        state = .error(.init(error.localizedDescription))
                        eventSubject.send(.error(.init(error.localizedDescription)))
                        _ = backgroundStates.remove(.updating)
                    }
                }
            }
            .asAnyCancellable()

            return state

        case let .updateUsername(username):
            userTaskCancellable?.cancel()

            userTaskCancellable = Task {
                do {
                    await MainActor.run {
                        _ = backgroundStates.insert(.updating)
                    }

                    try await updateUsername(username: username)

                    await MainActor.run {
                        state = .content
                        eventSubject.send(.updated)
                        _ = backgroundStates.remove(.updating)
                    }
                } catch {
                    await MainActor.run {
                        state = .error(.init(error.localizedDescription))
                        eventSubject.send(.error(.init(error.localizedDescription)))
                        _ = backgroundStates.remove(.updating)
                    }
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: - Load User Details

    private func loadDetails() async throws {
        guard let userID = user.id else { throw ErrorMessage("User ID is missing") }
        let request = Paths.getUserByID(userID: userID)
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.user = response.value
        }
    }

    // MARK: - Load Libraries

    private func loadLibraries(isHidden: Bool?) async throws {
        let request = Paths.getMediaFolders(isHidden: isHidden)
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.libraries = response.value.items ?? []
        }
    }

    // MARK: - Update User Policy

    private func updatePolicy(policy: UserPolicy) async throws {
        guard let userID = user.id else { throw ErrorMessage("User ID is missing") }
        let request = Paths.updateUserPolicy(userID: userID, policy)
        try await userSession.client.send(request)

        await MainActor.run {
            self.user.policy = policy
        }
    }

    // MARK: - Update User Configuration

    private func updateConfiguration(configuration: UserConfiguration) async throws {
        guard let userID = user.id else { throw ErrorMessage("User ID is missing") }
        let request = Paths.updateUserConfiguration(userID: userID, configuration)
        try await userSession.client.send(request)

        await MainActor.run {
            self.user.configuration = configuration
        }
    }

    // MARK: - Update Username

    private func updateUsername(username: String) async throws {
        guard let userID = user.id else { throw ErrorMessage("User ID is missing") }
        var updatedUser = user
        updatedUser.name = username

        let request = Paths.updateUser(userID: userID, updatedUser)
        try await userSession.client.send(request)

        await MainActor.run {
            self.user.name = username
            Notifications[.didChangeUserProfile].post(userID)
        }
    }
}
