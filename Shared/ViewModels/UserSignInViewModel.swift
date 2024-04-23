//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Factory
import Foundation
import JellyfinAPI
import Pulse

final class UserSignInViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case signInWithUserPass(username: String, password: String)
        case signInWithQuickConnect(authSecret: String)
        case cancelSignIn
    }

    // MARK: State

    enum State: Hashable {
        case initial
        case signingIn
        case signedIn
        case error(SignInError)
    }

    // TODO: Add more detailed errors
    enum SignInError: Error {
        case unknown
    }

    @Published
    var state: State = .initial
    var lastAction: Action? = nil

    @Published
    private(set) var publicUsers: [UserDto] = []
    @Published
    private(set) var quickConnectEnabled = false

    private var signInTask: Task<Void, Never>?

    let quickConnectViewModel: QuickConnectViewModel

    let client: JellyfinClient
    let server: SwiftfinStore.State.Server

    init(server: ServerState) {
        self.client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: server.currentURL),
            sessionDelegate: URLSessionProxyDelegate()
        )
        self.server = server
        self.quickConnectViewModel = .init(client: client)
        super.init()
    }

    func respond(to action: Action) -> State {
        switch action {
        case let .signInWithUserPass(username, password):
            guard state != .signingIn else { return .signingIn }
            Task {
                do {
                    try await signIn(username: username, password: password)
                } catch {
                    await MainActor.run {
                        state = .error(.unknown)
                    }
                }
            }
            return .signingIn
        case let .signInWithQuickConnect(authSecret):
            guard state != .signingIn else { return .signingIn }
            Task {
                do {
                    try await signIn(quickConnectSecret: authSecret)
                } catch {
                    await MainActor.run {
                        state = .error(.unknown)
                    }
                }
            }
            return .signingIn
        case .cancelSignIn:
            self.signInTask?.cancel()
            return .initial
        }
    }

    private func signIn(username: String, password: String) async throws {
        let username = username.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)

        let response = try await client.signIn(username: username, password: password)

        let user: UserState

        do {
            user = try await createLocalUser(response: response)
        } catch {
            if case let SwiftfinStore.Error.existingUser(existingUser) = error {
                user = existingUser
            } else {
                throw error
            }
        }

        Defaults[.lastServerUserID] = user.id
        Container.userSession.reset()
        Notifications[.didSignIn].post()
    }

    private func signIn(quickConnectSecret: String) async throws {
        let quickConnectPath = Paths.authenticateWithQuickConnect(.init(secret: quickConnectSecret))
        let response = try await client.send(quickConnectPath)

        let user: UserState

        do {
            user = try await createLocalUser(response: response.value)
        } catch {
            if case let SwiftfinStore.Error.existingUser(existingUser) = error {
                user = existingUser
            } else {
                throw error
            }
        }

        Defaults[.lastServerUserID] = user.id
        Container.userSession.reset()
        Notifications[.didSignIn].post()
    }

    func getPublicUsers() async throws {
        let publicUsersPath = Paths.getPublicUsers
        let response = try await client.send(publicUsersPath)

        await MainActor.run {
            publicUsers = response.value
        }
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
            throw SwiftfinStore.Error.existingUser(existingUser.state)
        }

        guard let storedServer = try? SwiftfinStore.dataStack.fetchOne(
            From<SwiftfinStore.Models.StoredServer>(),
            [
                Where<SwiftfinStore.Models.StoredServer>(
                    "id == %@",
                    server.id
                ),
            ]
        )
        else { fatalError("No stored server associated with given state server?") }

        let user = try SwiftfinStore.dataStack.perform { transaction in
            let newUser = transaction.create(Into<UserModel>())

            newUser.accessToken = accessToken
            newUser.appleTVID = ""
            newUser.id = id
            newUser.username = username

            let editServer = transaction.edit(storedServer)!
            editServer.users.insert(newUser)

            return newUser.state
        }

        return user
    }

    func checkQuickConnect() async throws {
        let quickConnectEnabledPath = Paths.getEnabled
        let response = try await client.send(quickConnectEnabledPath)
        let decoder = JSONDecoder()
        let isEnabled = try? decoder.decode(Bool.self, from: response.value)

        await MainActor.run {
            quickConnectEnabled = isEnabled ?? false
        }
    }
}
