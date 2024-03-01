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

final class UserSignInViewModel: ViewModel {
    @Published
    private(set) var publicUsers: [UserDto] = []

    let client: JellyfinClient
    let server: SwiftfinStore.State.Server

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

    // MARK: - Quick Connect

    /// The typical quick connect lifecycle is as follows:
    /// 1. User clicks quick connect
    /// 2. We fetch a secret and code from the server
    /// 3. Display the code to user, poll for authentication from server using secret
    /// 4. User enters code to the server
    /// 5. Authentication poll succeeds with another secret, use secret to log in

    @Published
    private(set) var quickConnectEnabled = false
    /// To maintain logic within this view model, we expose this property to track the status during quick connect execution.
    @Published
    private(set) var quickConnectStatus: QuickConnectStatus?

    /// How often to poll quick connect auth
    private let quickConnectPollTimeoutSeconds: UInt64 = 5

    private var quickConnectPollTask: Task<String, any Error>?

    enum QuickConnectStatus {
        case fetchingSecret
        case awaitingAuthentication(code: String)
        // Store the error and surface it to user if possible
        case error(Error)
        case authorized
    }

    enum QuickConnectError: Error {
        case fetchSecretFailed
        case pollingFailed
    }

    /// Signs in with quick connect. Returns whether sign in was successful.
    func signInWithQuickConnect() async -> Bool {
        do {
            await MainActor.run {
                quickConnectStatus = .fetchingSecret
            }
            let (initiateSecret, code) = try await startQuickConnect()

            await MainActor.run {
                quickConnectStatus = .awaitingAuthentication(code: code)
            }
            let authSecret = try await pollForAuthSecret(initialSecret: initiateSecret)

            try await signIn(quickConnectSecret: authSecret)
            await MainActor.run {
                quickConnectStatus = .authorized
            }

            return true
        } catch {
            await MainActor.run {
                quickConnectStatus = .error(error)
            }
            return false
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

    /// Gets secret and code to start quick connect authorization flow.
    private func startQuickConnect() async throws -> (secret: String, code: String) {
        logger.debug("Attempting to start quick connect...")

        let initiatePath = Paths.initiate
        let response = try await client.send(initiatePath)

        guard let secret = response.value.secret,
              let code = response.value.code
        else {
            throw QuickConnectError.fetchSecretFailed
        }

        return (secret, code)
    }

    private func pollForAuthSecret(initialSecret: String) async throws -> String {
        let task = Task {
            var authSecret: String?
            repeat {
                authSecret = try await checkAuth(initialSecret: initialSecret)
                try await Task.sleep(nanoseconds: 1_000_000_000 * quickConnectPollTimeoutSeconds)
            } while authSecret == nil
            return authSecret!
        }

        quickConnectPollTask = task
        return try await task.result.get()
    }

    private func checkAuth(initialSecret: String) async throws -> String? {
        logger.debug("Attempting to poll for quick connect auth")

        let connectPath = Paths.connect(secret: initialSecret)
        do {
            let response = try await client.send(connectPath)

            guard response.value.isAuthenticated ?? false else {
                return nil
            }
            guard let authSecret = response.value.secret else {
                logger.debug("Quick connect response was authorized but secret missing")
                throw QuickConnectError.pollingFailed
            }
            return authSecret
        } catch {
            throw QuickConnectError.pollingFailed
        }
    }

    func stopQuickConnectAuthCheck() {
        logger.debug("Stopping quick connect")

        quickConnectStatus = nil
        quickConnectPollTask?.cancel()
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
}
