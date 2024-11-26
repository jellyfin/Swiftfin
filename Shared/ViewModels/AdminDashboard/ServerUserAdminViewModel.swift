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
        case updateUsername(username: String)
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
        super.init()
        Notifications[.didChangeUserProfileImage].publisher
            .sink(receiveCompletion: { _ in }) { [weak self] notification in
                guard let self = self,
                      let newUser = notification.object as? UserDto,
                      newUser.id == self.user.id else { return }

                self.user = UserDto()
                self.user = newUser
            }
            .store(in: &cancellables)
    }

    // MARK: Respond

    func respond(to action: Action) -> State {
        switch action {
        case .cancel:
            resetTask?.cancel()
            return .initial

        case .loadDetails:
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
                    }
                }
            }
            .asAnyCancellable()

            return .initial

        case let .updateUsername(username):
            resetTask = Task {
                do {
                    try await updateUsername(username: username)
                    await MainActor.run {
                        self.state = .initial
                        self.eventSubject.send(.success)
                    }
                } catch {
                    await MainActor.run {
                        let jellyfinError = JellyfinAPIError(error.localizedDescription)
                        self.state = .error(jellyfinError)
                    }
                }
            }
            .asAnyCancellable()

            return .initial
        }
    }

    // MARK: - Update Username

    private func updateUsername(username: String) async throws {
        guard let userID = user.id else { return }
        var updatedUser = user
        updatedUser.name = username

        let request = Paths.updateUser(userID: userID, updatedUser)
        try await userSession.client.send(request)

        await MainActor.run {
            self.user.name = username
        }
    }

    // MARK: - Delete User's Profile Image

    func deleteCurrentUserProfileImage() {
        guard let userID = user.id else { return }

        Task {
            let request = Paths.deleteUserImage(
                userID: userID,
                imageType: "Primary"
            )
            let _ = try await userSession.client.send(request)

            let currentUserRequest = Paths.getCurrentUser
            let response = try await userSession.client.send(currentUserRequest)

            await MainActor.run {
                userSession.user.data = response.value
                Notifications[.didChangeUserProfileImage].post()
            }
        }
    }

    // MARK: - Load User

    private func loadDetails() async throws {
        guard let userID = user.id else { return }
        let request = Paths.getUserByID(userID: userID)
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.user = response.value
        }
    }
}
