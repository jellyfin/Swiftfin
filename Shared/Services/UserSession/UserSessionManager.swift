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
import JellyfinAPI
import Logging
import Synchronization

extension Container {

    var userSessionManager: Factory<UserSessionManager> {
        self { UserSessionManager() }.singleton
    }

    var currentUserSession: Factory<UserSession?> {
        self { self.userSessionManager().currentSession }
    }
}

@MainActor
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
        case accountUnavailable
    }

    enum AuthenticationError: Error {

        case missingAuthenticationAction
    }

    @Published
    private(set) var state: State = .initial

    private let session = Mutex<UserSession?>(nil)

    nonisolated var currentSession: UserSession? {
        session.withLock { $0 }
    }

    struct ReauthenticationRequest {

        let server: ServerState
        let user: UserState
    }

    @Published
    private(set) var reauthenticationRequest: ReauthenticationRequest?

    @Published
    private(set) var pendingDeepLink: DeepLink?

    let routePublisher = PassthroughSubject<NavigationRoute, Never>()

    private var lifecycleCancellables = Set<AnyCancellable>()
    var sessionCancellables = Set<AnyCancellable>()

    let logger = Logger.swiftfin()

    @LazyInjected(\.mediaPlayerManager)
    private(set) var mediaPlayerManager

    private var sessionTransition: Task<Void, Never>?

    var hasActivePlayback: Bool {
        mediaPlayerManager.hasActivePlayback
    }

    nonisolated init() {}

    func start() async {
        guard state == .initial else { return }

        if let sessionTransition {
            await sessionTransition.value
            return
        }

        var session: UserSession?
        if !Defaults[.signOutOnClose], case let .signedIn(userID) = Defaults[.lastSignedInUserID] {
            do {
                session = try storedSession(for: userID)
            } catch {
                logger.error("Unable to restore launch session", metadata: ["error": .string(error.localizedDescription)])
            }
        }

        await updateCurrentSession(with: session)
    }

    func signIn(userID: String) async throws {
        let session = try storedSession(for: userID)
        reauthenticationRequest = nil
        await updateCurrentSession(with: session)

        Task {
            guard currentSession === session else { return }

            await refreshServerInformationIfNeeded(reason: .explicitSignIn)
        }
    }

    func signOut(reason: SignOutReason) async {
        guard currentSession != nil || sessionTransition != nil else { return }

        let expiredSession = reason == .authenticationExpired ? currentSession : nil
        await updateCurrentSession(with: nil)
        if let expiredSession, currentSession == nil, sessionTransition == nil {
            reauthenticationRequest = .init(server: expiredSession.server, user: expiredSession.user)
        }

        logger.info(
            "Signed out current user",
            metadata: ["reason": .string(String(describing: reason))]
        )
    }

    func consumeReauthenticationRequest() -> ReauthenticationRequest? {
        defer { reauthenticationRequest = nil }
        return reauthenticationRequest
    }

    func scheduleServerConnectionResolution() {
        currentSession?.serverConnectionManager.scheduleConnectionResolution()
    }

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

    func consumePendingDeepLink() -> DeepLink? {
        defer {
            pendingDeepLink = nil
        }

        return pendingDeepLink
    }

    func appDidEnterBackground() {
        Defaults[.backgroundTimeStamp] = Date.now
    }

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

        if let storedPin = dependency(\.keychainService).get("\(user.id)-pin") {
            guard pinPolicy.pin == storedPin else {
                throw ErrorMessage(L10n.incorrectPinForUser(user.username))
            }
        }
    }

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
            _ = try await currentSession.getUser(id: currentSession.user.id)

            guard self.currentSession === currentSession else { return }

            Defaults[.lastServerInformationRefreshDate] = Date.now
        } catch {
            logger.error(
                "Unable to refresh server and user information",
                metadata: ["error": .string(error.localizedDescription)]
            )
        }
    }

    private func observeAppLifecycle() {
        Notifications[.applicationDidEnterBackground]
            .publisher
            .sink { [weak self] in
                Task {
                    self?.appDidEnterBackground()
                }
            }
            .store(in: &lifecycleCancellables)

        Notifications[.applicationWillEnterForeground]
            .publisher
            .sink { [weak self] in
                Task {
                    await self?.appWillEnterForeground()
                }
            }
            .store(in: &lifecycleCancellables)
    }

    private func updateCurrentSession(with newSession: UserSession?) async {
        let previous = sessionTransition
        let task = Task {
            await previous?.value
            await applyCurrentSession(newSession)
        }

        sessionTransition = task
        await task.value

        if sessionTransition == task {
            sessionTransition = nil
        }
    }

    /// Serialize transitions because starting and stopping session services can suspend
    private func applyCurrentSession(_ newSession: UserSession?) async {
        if state == .initial {
            observeAppLifecycle()
        }

        sessionCancellables.removeAll()
        mediaPlayerManager.stop()
        currentSession?.willStop()
        Defaults[.lastSignedInUserID] = newSession.map { .signedIn(userID: $0.user.id) } ?? .signedOut
        await newSession?.willStart()

        session.withLock { $0 = newSession }
        state = newSession == nil ? .signedOut : .signedIn

        guard let newSession else { return }

        observeSocketCommands(on: newSession.serverSocketManager)
        newSession.users
            .changes
            .sink { [weak self, weak newSession] change in
                guard let session = newSession else { return }

                switch change {
                case let .updated(user):
                    guard user.id == session.user.id, user.policy?.isDisabled == true else { return }

                case let .deleted(id):
                    guard id == session.user.id else { return }
                }

                Task { [weak self, weak session] in
                    guard let self, let session, self.currentSession === session else { return }

                    await self.signOut(reason: .accountUnavailable)
                }
            }
            .store(in: &sessionCancellables)

        newSession.didStart()
    }

    private func storedSession(for userID: String) throws -> UserSession {
        guard let user = StoredValues[.User.users].first(property: \.id, equalTo: userID),
              let server = StoredValues[.Server.servers].first(property: \.id, equalTo: user.serverID)
        else {
            throw UserSessionError.invalidStoredSession(userID: userID)
        }

        return .init(
            server: server,
            user: user
        )
    }
}
