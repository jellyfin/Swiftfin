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

/// Handles getting and exposing quick connect code and related states and polling for authentication secret and
/// exposing it to a consumer.
/// __Does not handle using the authentication secret itself to sign in.__
final class QuickConnectViewModel: ViewModel, Stateful {
    // MARK: Action

    enum Action {
        case startQuickConnect
        case cancelQuickConnect
    }

    // MARK: State

    // The typical quick connect lifecycle is as follows:
    enum State: Equatable {
        // 0. User has not interacted with quick connect
        case initial
        // 1. User clicks quick connect
        case fetchingSecret
        // 2. We fetch a secret and code from the server
        // 3. Display the code to user, poll for authentication from server using secret
        // 4. User enters code to the server
        case awaitingAuthentication(code: String)
        // 5. Authentication poll succeeds with another secret. A consumer uses this secret to sign in.
        //    In particular, the responsibility to consume this secret and handle any errors and state changes
        //    is deferred to the consumer.
        case authenticated(secret: String)
        // Store the error and surface it to user if possible
        case error(QuickConnectError)
    }

    // TODO: Consider giving these errors a message and using it in the QuickConnectViews
    enum QuickConnectError: Error {
        case fetchSecretFailed
        case pollingFailed
        case unknown
    }

    @Published
    var state: State = .initial

    let client: JellyfinClient

    /// How often to poll quick connect auth
    private let quickConnectPollTimeoutSeconds: Int = 5
    private let quickConnectMaxRetries: Int = 200

    private var quickConnectPollTask: Task<String, any Error>?

    init(client: JellyfinClient) {
        self.client = client
        super.init()
    }

    func respond(to action: Action) -> State {
        switch action {
        case .startQuickConnect:
            Task {
                await fetchAuthCode()
            }
            return .fetchingSecret
        case .cancelQuickConnect:
            stopQuickConnectAuthCheck()
            return .initial
        }
    }

    /// Retrieves sign in secret, and stores it in the state for a consumer to use.
    private func fetchAuthCode() async {
        do {
            await MainActor.run {
                state = .fetchingSecret
            }
            let (initiateSecret, code) = try await startQuickConnect()

            await MainActor.run {
                state = .awaitingAuthentication(code: code)
            }
            let authSecret = try await pollForAuthSecret(initialSecret: initiateSecret)

            await MainActor.run {
                state = .authenticated(secret: authSecret)
            }
        } catch let error as QuickConnectError {
            await MainActor.run {
                state = .error(error)
            }
        } catch {
            await MainActor.run {
                state = .error(.unknown)
            }
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
            for _ in 1 ... quickConnectMaxRetries {
                authSecret = try await checkAuth(initialSecret: initialSecret)
                if authSecret != nil { break }

                try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * quickConnectPollTimeoutSeconds))
            }
            guard let authSecret = authSecret else {
                logger.warning("Hit max retries while using quick connect, did the `pollForAuthSecret` task keep running after signing in?")
                throw QuickConnectError.pollingFailed
            }
            return authSecret
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

    private func stopQuickConnectAuthCheck() {
        logger.debug("Stopping quick connect")

        state = .initial
        quickConnectPollTask?.cancel()
    }
}
