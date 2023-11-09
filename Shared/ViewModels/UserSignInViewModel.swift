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
    /// We want to tell the monitor task when we're ready to poll for authentication. Without this, we may encounter
    /// a race condition where the monitor task expects the secret before it's fetched and exits prematurely.
    @Published
    private(set) var quickConnectStatus: QuickConnectStatus?

    private let quickConnectPollTimeoutSeconds: UInt64 = 5

    /// We don't use Timer.scheduledTimer because checking quick connect status is async. We only want to start the next
    /// poll when the current has finished.
    private var quickConnectPollTask: Task<Void, Never>?
    /// When two quick connect tasks are started for whatever reason, cancelling the repeating task above seems to fail
    /// and the attempted cancelled task seems to continue to spawn more repeating tasks. We ensure only a single
    /// poll task continues to live with this ID.
    private var quickConnectPollTaskID: UUID?
    /// If, for whatever reason, the monitor task keeps going, we don't want to let it silently run forever.
    private let quickConnectMaxRetries = 200

    enum QuickConnectStatus {
        case fetchingSecret
        // After secret and code is fetched from the server, store it in the associated value as:
        //                         (secret, code)
        case awaitingAuthentication(String, String)
        // Store the error and surface it to user if possible
        case fetchingSecretFailed(Error?)
    }

    func startQuickConnect() -> AsyncStream<QuickConnectResult> {
        logger.debug("Attempting to start quick connect...")
        quickConnectStatus = .fetchingSecret

        Task {
            let initiatePath = Paths.initiate
            do {
                let response = try await client.send(initiatePath)

                guard let secret = response.value.secret,
                      let code = response.value.code
                else {
                    // TODO: Create an error & display it in QuickConnectView (iOS)/UserSignInView (tvOS)
                    quickConnectStatus = .fetchingSecretFailed(nil)
                    return
                }

                await MainActor.run {
                    quickConnectStatus = .awaitingAuthentication(secret, code)
                }

            } catch {
                quickConnectStatus = .fetchingSecretFailed(error)
            }
        }

        let taskID = UUID()
        quickConnectPollTaskID = taskID

        return .init { continuation in
            checkAuthStatus(continuation: continuation, id: taskID)
        }
    }

    private func checkAuthStatus(continuation: AsyncStream<QuickConnectResult>.Continuation, id: UUID, tries: Int = 0) {
        let task = Task {
            // Don't race into failure while we're fetching the secret.
            while case .fetchingSecret = quickConnectStatus {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

            logger.debug("Attempting to poll for quick connect auth on taskID \(id)")

            guard case let .awaitingAuthentication(quickConnectSecret, _) = quickConnectStatus,
                  quickConnectPollTaskID == id else { return }

            if tries > quickConnectMaxRetries {
                logger.warning("Hit max retries while using quick connect, did `checkAuthStatus` keep running after signing in?")
                stopQuickConnectAuthCheck()
                return
            }

            let connectPath = Paths.connect(secret: quickConnectSecret)
            let response = try? await client.send(connectPath)

            if let responseValue = response?.value, responseValue.isAuthenticated ?? false {
                continuation.yield(responseValue)

                await MainActor.run {
                    stopQuickConnectAuthCheck()
                }

                return
            }

            try? await Task.sleep(nanoseconds: 1_000_000_000 * quickConnectPollTimeoutSeconds)

            checkAuthStatus(continuation: continuation, id: id, tries: tries + 1)
        }

        quickConnectPollTask = task
    }

    func stopQuickConnectAuthCheck() {
        logger.debug("Stopping quick connect")

        quickConnectStatus = nil
        quickConnectPollTaskID = nil
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
}
