//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Defaults
import Factory
import Foundation
import Get
import JellyfinAPI
import Pulse

final class UserSignInViewModel: ViewModel, Eventful, Stateful {

    // MARK: Event

    enum Event {
        case duplicateUser(UserState)
        case error(JellyfinAPIError)
    }

    // MARK: Action

    enum Action: Equatable {
        case getPublicData
        case signIn(username: String, password: String)
        case signInQuickConnect(secret: String)
        case cancel
    }

    // MARK: State

    enum State: Hashable {
        case initial
        case signingIn
    }

    @Published
    var isQuickConnectEnabled = false
    @Published
    var publicUsers: [UserDto] = []
    @Published
    var state: State = .initial

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    let quickConnect: QuickConnect
    let server: ServerState

    private var eventSubject: PassthroughSubject<Event, Never> = .init()
    private var signInTask: AnyCancellable?

    init(server: ServerState) {
        self.server = server
        self.quickConnect = QuickConnect(client: server.client)

        super.init()

        quickConnect.$state
            .sink { [weak self] state in
                if case let QuickConnect.State.authenticated(secret: secret) = state {
                    guard let self else { return }

                    Task {
                        await self.send(.signInQuickConnect(secret: secret))
                    }
                }
            }
            .store(in: &cancellables)
    }

    func respond(to action: Action) -> State {
        switch action {
        case .getPublicData:
            Task { [weak self] in
                let isQuickConnectEnabled = try await self?.retrieveQuickConnectEnabled()
                let publicUsers = try await self?.retrievePublicUsers()

                guard let self else { return }

                await MainActor.run {
                    self.isQuickConnectEnabled = isQuickConnectEnabled ?? false
                    self.publicUsers = publicUsers ?? []
                }
            }
            .store(in: &cancellables)

            return state
        case let .signIn(username, password):
            signInTask?.cancel()

            signInTask = Task {
                do {
                    try await signIn(username: username, password: password)
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .signingIn
        case let .signInQuickConnect(secret):
            signInTask?.cancel()

            signInTask = Task {
                do {
                    try await signIn(secret: secret)
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .signingIn
        case .cancel:
            signInTask?.cancel()

            return .initial
        }
    }

    private func signIn(username: String, password: String) async throws {
        let username = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)

        let password = password
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)

        let response = try await server.client.signIn(username: username, password: password)
        let user = try await saveUser(with: response)

        Defaults[.lastSignedInUserID] = user.id
        Container.userSession.reset()
        Notifications[.didSignIn].post()
    }

    private func signIn(secret: String) async throws {

        let response = try await server.client.signIn(quickConnectSecret: secret)
        let user = try await saveUser(with: response)

        Defaults[.lastSignedInUserID] = user.id
        Container.userSession.reset()
        Notifications[.didSignIn].post()
    }

    private func user(for id: String) -> UserState? {
        try? SwiftfinStore
            .dataStack
            .fetchOne(From<UserModel>().where(\.$id == id))?
            .state
    }

    @MainActor
    private func saveUser(with response: AuthenticationResult) async throws -> UserState {

        guard let accessToken = response.accessToken,
              let username = response.user?.name,
              let id = response.user?.id else { throw JellyfinAPIError("Missing user data from network call") }

        // User already signed in, just sign in
        if let existingUser = user(for: id) {
            return existingUser
        }

        guard let serverModel = try? dataStack.fetchOne(From<ServerModel>().where(\.$id == server.id)) else {
            logger.critical("Unable to find server to save user")
            throw JellyfinAPIError("An internal error has occurred")
        }

        let user = try dataStack.perform { transaction in
            let newUser = transaction.create(Into<UserModel>())

//            newUser.accessToken = accessToken
            newUser.appleTVID = ""
            newUser.id = id
            newUser.username = username
//            newUser.image = profileImage

            let editServer = transaction.edit(serverModel)!
            editServer.users.insert(newUser)

            return newUser.state
        }

        return user
    }

    private func retrievePublicUsers() async throws -> [UserDto] {
        let publicUsersPath = Paths.getPublicUsers
        let response = try await server.client.send(publicUsersPath)

        return response.value
    }

    private func retrieveQuickConnectEnabled() async throws -> Bool {
        let request = Paths.getEnabled
        let response = try await server.client.send(request)

        let isEnabled = try? JSONDecoder().decode(Bool.self, from: response.value)
        return isEnabled ?? false
    }
}
