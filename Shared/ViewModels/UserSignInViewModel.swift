//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Factory
import Foundation
import JellyfinAPI
import Pulse

final class UserSignInViewModel: ViewModel {

    @Published
    private(set) var publicUsers: [UserDto] = []
    @Published
    private(set) var quickConnectCode: String?
    @Published
    private(set) var quickConnectEnabled = false

    let client: JellyfinClient
    let server: SwiftfinStore.State.Server

    private var quickConnectTask: Task<Void, Never>?
    private var quickConnectTimer: RepeatingTimer?
    private var quickConnectSecret: String?

    init(server: ServerState) {
        self.client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: server.currentURL),
            sessionDelegate: URLSessionProxyDelegate()
        )
        self.server = server
        super.init()
    }

    func signIn(username: String, password: String) async throws {

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

    func getPublicUsers() async throws {
        let publicUsersPath = Paths.getPublicUsers
        let response = try await client.send(publicUsersPath)

        await MainActor.run {
            publicUsers = response.value
        }
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

    func startQuickConnect() -> AsyncStream<QuickConnectResult> {
        Task {

            let initiatePath = Paths.initiate
            let response = try? await client.send(initiatePath)

            guard let response else { return }

            await MainActor.run {
                quickConnectSecret = response.value.secret
                quickConnectCode = response.value.code
            }
        }

        return .init { continuation in

            checkAuthStatus(continuation: continuation)
        }
    }

    private func checkAuthStatus(continuation: AsyncStream<QuickConnectResult>.Continuation) {

        let task = Task {
            guard let quickConnectSecret else { return }
            let connectPath = Paths.connect(secret: quickConnectSecret)
            let response = try? await client.send(connectPath)

            if let responseValue = response?.value, responseValue.isAuthenticated ?? false {
                continuation.yield(responseValue)
                return
            }

            try? await Task.sleep(nanoseconds: 5_000_000_000)

            checkAuthStatus(continuation: continuation)
        }

        self.quickConnectTask = task
    }

    func stopQuickConnectAuthCheck() {
        self.quickConnectTask?.cancel()
    }

    func signIn(quickConnectSecret: String) async throws {
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
}
