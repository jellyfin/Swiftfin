//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import FactoryKit
import Foundation
import Get
import JellyfinAPI
import KeychainSwift
import Logging

extension Container {

    var userSessionManager: Factory<UserSessionManager> {
        self { UserSessionManager() }
            .singleton
    }

    var currentUserSession: Factory<UserSession?> {
        self { self.userSessionManager().currentSession }
            .cached
    }
}

final class UserSessionManager: ObservableObject {

    enum State: Equatable {

        case initial
        case signedOut
        case signedIn
    }

    enum SignOutReason {

        case backgroundTimeout
        case explicit
        case authenticationExpired
    }

    enum AuthenticationError: Error {

        case missingAuthenticationAction
    }

    @Injected(\.keychainService)
    private var keychain: KeychainSwift

    @Published
    private(set) var state: State = .initial

    @Published
    private(set) var currentSession: UserSession?

    struct ReauthenticationRequest {
        let server: ServerState
        let user: UserState
    }

    @Published
    private(set) var reauthenticationRequest: ReauthenticationRequest?

    @MainActor
    private var authenticationChecks: [ObjectIdentifier: Task<Bool, Never>] = [:]

    @Published
    private(set) var pendingDeepLink: DeepLink?

    let routePublisher = PassthroughSubject<NavigationRoute, Never>()

    var cancellables = Set<AnyCancellable>()

    let logger = Logger.swiftfin()

    @Injected(\.mediaPlayerManager)
    private(set) var mediaPlayerManager

    @MainActor
    private var sessionTransition: (id: UUID, task: Task<Void, Never>)?

    @MainActor
    var hasActivePlayback: Bool {
        mediaPlayerManager.hasActivePlayback
    }

    init() {
        setupObservations()
    }

    @MainActor
    func start() async {
        guard state == .initial else { return }

        do {
            if Defaults[.signOutOnClose] {
                Defaults[.lastSignedInUserID] = .signedOut
            }

            try await updateCurrentSession(with: resolveStoredSession())
        } catch {
            logger.error(
                "Unable to restore launch session",
                metadata: ["error": .string(error.localizedDescription)]
            )

            await updateCurrentSession(with: nil)
        }
    }

    @MainActor
    func signIn(userID: String) async throws {
        reauthenticationRequest = nil
        Defaults[.lastSignedInUserID] = .signedIn(userID: userID)
        try await updateCurrentSession(with: resolveStoredSession())

        Task {
            await refreshServerInformationIfNeeded(reason: .explicitSignIn)
        }
    }

    @MainActor
    func signOut(reason: SignOutReason) async {
        guard currentSession != nil || sessionTransition != nil else { return }

        Defaults[.lastSignedInUserID] = .signedOut
        await updateCurrentSession(with: nil)

        logger.info(
            "Signed out current user",
            metadata: ["reason": .string(String(describing: reason))]
        )
    }

    /// Confirm a rejected token without treating permission or connection failures as sign-out.
    @MainActor
    func handleUnauthorizedResponse(from session: UserSession, accessToken: String) async -> Bool {
        guard currentSession === session, session.user.accessToken == accessToken else { return true }

        let id = ObjectIdentifier(session)
        if let check = authenticationChecks[id] {
            return await check.value
        }

        let check = Task { @MainActor in
            do {
                // This uses a separate client so a failed check cannot recursively trigger another check.
                _ = try await session.user.getUserData(server: session.server)
            } catch APIError.unacceptableStatusCode(401) {
                guard currentSession === session, session.user.accessToken == accessToken else { return true }

                await signOut(reason: .authenticationExpired)

                if currentSession == nil, Defaults[.lastSignedInUserID] == .signedOut {
                    reauthenticationRequest = .init(server: session.server, user: session.user)
                }
                return true
            } catch {
                // Keep the session when the authentication check cannot reach the server.
            }
            return currentSession !== session || session.user.accessToken != accessToken
        }
        authenticationChecks[id] = check
        defer { authenticationChecks[id] = nil }
        return await check.value
    }

    @MainActor
    func consumeReauthenticationRequest() -> ReauthenticationRequest? {
        defer { reauthenticationRequest = nil }
        return reauthenticationRequest
    }

    @MainActor
    private func stopActivePlayback() async {
        mediaPlayerManager.stop()
    }

    @MainActor
    func scheduleServerConnectionResolution() {
        currentSession?.serverConnectionManager.scheduleConnectionResolution()
    }

    @MainActor
    func handleOpenURL(
        _ url: URL,
        authenticationAction: LocalUserAuthenticationAction
    ) async {
        guard let deepLink = DeepLink(url) else { return }

        do {
            let deepLinkSession = try session(for: deepLink)
            let currentSession = currentSession
            let isSameUserSession = currentSession?.server.id == deepLinkSession.server.id && currentSession?.user.id == deepLinkSession
                .user.id

            if !isSameUserSession {
                try await authenticate(
                    user: deepLinkSession.user,
                    authenticationAction: authenticationAction
                )

                try await signIn(userID: deepLinkSession.user.id)
            }

            pendingDeepLink = deepLink
        } catch {
            logger.error(
                "Failed to process deep link",
                metadata: ["error": .string(error.localizedDescription)]
            )
        }
    }

    @MainActor
    func consumePendingDeepLink() -> DeepLink? {
        defer {
            pendingDeepLink = nil
        }

        return pendingDeepLink
    }

    @MainActor
    func appDidEnterBackground() {
        Defaults[.backgroundTimeStamp] = Date.now
    }

    @MainActor
    func appWillEnterForeground() async {
        scheduleServerConnectionResolution()

        Task {
            await refreshServerInformationIfNeeded(reason: .stale)
        }

        guard currentSession != nil, Defaults[.signOutOnBackground], !hasActivePlayback else { return }

        let backgroundedInterval = Date.now.timeIntervalSince(Defaults[.backgroundTimeStamp])

        if backgroundedInterval > Defaults[.backgroundSignOutInterval] {
            await signOut(reason: .backgroundTimeout)
        }
    }

    private enum ServerInformationRefreshReason {

        case explicitSignIn
        case stale
    }

    private func session(for deepLink: DeepLink) throws -> (server: ServerState, user: UserState) {
        guard let server = StoredValues[.Server.servers].first(where: { $0.id == deepLink.serverID }) else {
            throw DeepLinkError.missingServer(deepLink.serverID)
        }
        guard let user = StoredValues[.User.users].first(where: { $0.id == deepLink.userID && $0.serverID == server.id }) else {
            throw DeepLinkError.missingUser(deepLink.userID)
        }

        return (server, user)
    }

    private func authenticate(
        user: UserState,
        authenticationAction: LocalUserAuthenticationAction
    ) async throws {
        guard user.accessPolicy != .none else { return }

        let evaluatedPolicy = try await authenticationAction(
            policy: user.accessPolicy,
            reason: user.accessPolicy.authenticateReason(user: user)
        )

        guard let pinPolicy = evaluatedPolicy as? PinEvaluatedUserAccessPolicy else { return }

        if let storedPin = keychain.get("\(user.id)-pin") {
            guard pinPolicy.pin == storedPin else {
                throw ErrorMessage(L10n.incorrectPinForUser(user.username))
            }
        }
    }

    @MainActor
    private func refreshServerInformationIfNeeded(reason: ServerInformationRefreshReason) async {
        guard let currentSession else { return }

        switch reason {
        case .explicitSignIn:
            break
        case .stale:
            guard Defaults[.lastServerInformationRefreshDate].isStale(with: .hours(24)) else { return }
        }

        do {
            try await currentSession.server.updateServerInfo()
            try await currentSession.user.updateUserData(server: currentSession.server)

            Defaults[.lastServerInformationRefreshDate] = Date.now
        } catch {
            logger.error(
                "Unable to refresh server and user information",
                metadata: ["error": .string(error.localizedDescription)]
            )
        }
    }

    private func setupObservations() {
        Notifications[.applicationDidEnterBackground]
            .publisher
            .sink { [weak self] in
                Task { @MainActor in
                    self?.appDidEnterBackground()
                }
            }
            .store(in: &cancellables)

        Notifications[.applicationWillEnterForeground]
            .publisher
            .sink { [weak self] in
                Task { @MainActor in
                    await self?.appWillEnterForeground()
                }
            }
            .store(in: &cancellables)

        observeSocketCommands()
    }

    @MainActor
    private func updateCurrentSession(with newSession: UserSession?) async {
        let previous = sessionTransition?.task
        let id = UUID()

        let task = Task {
            await previous?.value
            await applyCurrentSession(newSession)
        }

        sessionTransition = (id, task)
        await task.value

        if sessionTransition?.id == id {
            sessionTransition = nil
        }
    }

    /// Serialize transitions because starting and stopping session services can suspend
    @MainActor
    private func applyCurrentSession(_ newSession: UserSession?) async {
        let previousSession = currentSession

        await stopActivePlayback()
        previousSession?.willStop()
        await newSession?.willStart()

        currentSession = newSession
        Container.shared.currentUserSession.reset()

        if newSession == nil {
            state = .signedOut
        } else {
            state = .signedIn
        }

        newSession?.didStart()
    }

    private func resolveStoredSession() throws -> UserSession? {
        guard case let .signedIn(userId) = Defaults[.lastSignedInUserID] else { return nil }
        guard let user = StoredValues[.User.users].first(property: \.id, equalTo: userId),
              let server = StoredValues[.Server.servers].first(property: \.id, equalTo: user.serverID)
        else {
            Defaults[.lastSignedInUserID] = .signedOut
            throw UserSessionError.invalidStoredSession(userID: userId)
        }

        return .init(
            server: server,
            user: user
        )
    }
}
