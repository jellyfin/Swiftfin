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

    @Published
    private(set) var pendingDeepLink: DeepLink?

    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger.swiftfin()
    private var mediaPlayerManager: MediaPlayerManager?

    @MainActor
    var hasActivePlayback: Bool {
        guard let mediaPlayerManager else { return false }
        return mediaPlayerManager.state != .stopped
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

            try updateCurrentSession(with: resolveStoredSession())
        } catch {
            logger.error(
                "Unable to restore launch session",
                metadata: ["error": .string(error.localizedDescription)]
            )

            updateCurrentSession(with: nil)
        }
    }

    private func refreshCurrentSession() {
        do {
            try updateCurrentSession(with: resolveStoredSession())
        } catch {
            logger.error(
                "Unable to refresh current user session",
                metadata: ["error": .string(error.localizedDescription)]
            )
            updateCurrentSession(with: nil)
        }
    }

    func signIn(userID: String) throws {
        Defaults[.lastSignedInUserID] = .signedIn(userID: userID)
        try updateCurrentSession(with: resolveStoredSession())

        Task {
            await refreshServerInformationIfNeeded(reason: .explicitSignIn)
        }
    }

    @MainActor
    func signOut(reason: SignOutReason) {
        guard currentSession != nil else { return }

        Defaults[.lastSignedInUserID] = .signedOut
        refreshCurrentSession()

        logger.info(
            "Signed out current user",
            metadata: ["reason": .string(String(describing: reason))]
        )
    }

    @MainActor
    private func stopActivePlayback() async {
        await mediaPlayerManager?.stop()
        self.mediaPlayerManager = nil
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

                if hasActivePlayback {
                    await stopActivePlayback()
                }

                try signIn(userID: deepLinkSession.user.id)
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
    func appWillEnterForeground() {
        refreshCurrentSession()

        Task {
            await refreshServerInformationIfNeeded(reason: .stale)
        }

        guard currentSession != nil else { return }
        guard Defaults[.signOutOnBackground] else { return }
        guard !hasActivePlayback else { return }

        let backgroundedInterval = Date.now.timeIntervalSince(Defaults[.backgroundTimeStamp])
        if backgroundedInterval > Defaults[.backgroundSignOutInterval] {
            signOut(reason: .backgroundTimeout)
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
                    self?.appWillEnterForeground()
                }
            }
            .store(in: &cancellables)

        Container.shared.mediaPlayerManagerPublisher()
            .sink { [weak self] manager in
                Task { @MainActor in
                    self?.mediaPlayerManager = manager
                }
            }
            .store(in: &cancellables)
    }

    private func updateCurrentSession(with newSession: UserSession?) {
        let previousSession = currentSession
        currentSession = newSession
        Container.shared.currentUserSession.reset()

        if previousSession?.server.id != newSession?.server.id || previousSession?.user.id != newSession?.user.id {
            Container.shared.mediaPlayerManager.reset()
        }

        if newSession == nil {
            state = .signedOut
        } else {
            state = .signedIn
        }

        Task { @MainActor in
            previousSession?.willStop()
            newSession?.start()
        }
    }

    private func resolveStoredSession() throws -> UserSession? {
        guard case let .signedIn(userId) = Defaults[.lastSignedInUserID] else { return nil }

        guard let user = StoredValues[.User.users].first(where: { $0.id == userId }) else {
            Defaults[.lastSignedInUserID] = .signedOut
            throw UserSessionError.invalidStoredSession(userID: userId)
        }

        guard let server = StoredValues[.Server.servers].first(where: { $0.id == user.serverID }) else {
            Defaults[.lastSignedInUserID] = .signedOut
            throw UserSessionError.invalidStoredSession(userID: userId)
        }

        return .init(
            server: server,
            user: user
        )
    }
}
