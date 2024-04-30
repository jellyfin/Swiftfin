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
        case getPublicUsers
        case signIn(username: String, password: String)
        case signInWithQuickConnect(authSecret: String)
        case cancel
    }

    // MARK: State

    enum State: Hashable {
        case initial
        case signingIn
    }

    @Published
    var publicUsers: [UserDto] = []
    @Published
    var quickConnectEnabled = false
    @Published
    var state: State = .initial

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    let quickConnectViewModel: QuickConnectViewModel
    let server: ServerState

    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    init(server: ServerState) {
        self.server = server
        self.quickConnectViewModel = .init(client: server.client)
        super.init()
    }

    func respond(to action: Action) -> State {
        .initial

//        switch action {
//        case let .signIn(username, password):
//            guard state != .signingIn else { return .signingIn }
//            Task {
//                do {
//                    try await signIn(username: username, password: password)
//                } catch {
//                    await MainActor.run {
//                        state = .error(.init(error.localizedDescription))
//                    }
//                }
//            }
//
//            return .signingIn
//        case let .signInWithQuickConnect(authSecret):
//            guard state != .signingIn else { return .signingIn }
//            Task {
//                do {
//                    try await signIn(quickConnectSecret: authSecret)
//                } catch {
//                    await MainActor.run {
//                        state = .error(.init(error.localizedDescription))
//                    }
//                }
//            }
//            return .signingIn
//        case .cancel:
//            return .initial
//        }
    }

    private func signIn(username: String, password: String) async throws {
        let username = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)

        let password = password
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)

        let response = try await server.client.signIn(username: username, password: password)

        let user: UserState

        do {
            user = try await createLocalUser(response: response)
        } catch {
            throw error
//            if case let SwiftfinStore.Error.existingUser(existingUser) = error {
//                user = existingUser
//            } else {
//                throw error
//            }
        }

        Defaults[.lastSignedInUserID] = user.id
        Container.userSession.reset()
        Notifications[.didSignIn].post()
    }

    private func signIn(quickConnectSecret: String) async throws {
        let quickConnectPath = Paths.authenticateWithQuickConnect(.init(secret: quickConnectSecret))
        let response = try await server.client.send(quickConnectPath)

        let user: UserState

        do {
            user = try await createLocalUser(response: response.value)
        } catch {
            throw error
//            if case let SwiftfinStore.Error.existingUser(existingUser) = error {
//                user = existingUser
//            } else {
//                throw error
//            }
        }

        Defaults[.lastSignedInUserID] = user.id
        Container.userSession.reset()
        Notifications[.didSignIn].post()
    }

    private func getPublicUsers() async throws -> [UserDto] {
        let publicUsersPath = Paths.getPublicUsers
        let response = try await server.client.send(publicUsersPath)

        return response.value
    }

    @MainActor
    private func createLocalUser(response: AuthenticationResult) async throws -> UserState {
        guard let accessToken = response.accessToken,
              let username = response.user?.name,
              let id = response.user?.id else { throw JellyfinAPIError("Missing user data from network call") }

        if let existingUser = try? SwiftfinStore.dataStack.fetchOne(
            From<UserModel>(),
            [Where<UserModel>(
                "id == %@",
                id
            )]
        ) {
//            throw SwiftfinStore.Error.existingUser(existingUser.state)
        }

        guard let storedServer = try? SwiftfinStore.dataStack.fetchOne(
            From<ServerModel>(),
            [
                Where<ServerModel>(
                    "id == %@",
                    server.id
                ),
            ]
        )
        else { fatalError("No stored server associated with given state server?") }

        let user = try SwiftfinStore.dataStack.perform { transaction in
            let newUser = transaction.create(Into<UserModel>())

//            newUser.accessToken = accessToken
            newUser.appleTVID = ""
            newUser.id = id
            newUser.username = username
//            newUser.image = profileImage

            let editServer = transaction.edit(storedServer)!
            editServer.users.insert(newUser)

            return newUser.state
        }

        return user
    }

    func checkQuickConnect() async throws {
        let quickConnectEnabledPath = Paths.getEnabled
        let response = try await server.client.send(quickConnectEnabledPath)
        let decoder = JSONDecoder()
        let isEnabled = try? decoder.decode(Bool.self, from: response.value)

        await MainActor.run {
            quickConnectEnabled = isEnabled ?? false
        }
    }
}
