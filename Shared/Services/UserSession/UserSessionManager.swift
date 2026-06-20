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

    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger.swiftfin()
    private let serverInformationRefreshPolicy = DataRefreshPolicy.daily
    private var mediaPlayerManager: MediaPlayerManager?

    @Injected(\.deepLinkHandler)
    private var deepLinkHandler: DeepLinkHandler

    @Published
    private(set) var state: State = .initial

    @Published
    private(set) var currentSession: UserSession?

    @MainActor
    var hasActivePlayback: Bool {
        guard let mediaPlayerManager else { return false }
        return mediaPlayerManager.state != .stopped
    }

    init() {
        observeMediaPlayerManager()
        observeAppLifecycle()
    }

    @MainActor
    func start() async {
        guard state == .initial else { return }

        do {
            try restoreLaunchSession()

            Task {
                await refreshServerInformationIfNeeded(reason: .stale)
            }
        } catch UserSessionError.invalidStoredSession {
            updateCurrentSession(with: nil)
        } catch {
            logger.error(
                "Unable to restore launch session",
                metadata: ["error": .string(error.localizedDescription)]
            )
            updateCurrentSession(with: nil)
        }
    }

    @MainActor
    func restoreLaunchSession() throws {
        if Defaults[.signOutOnClose] {
            Defaults[.lastSignedInUserID] = .signedOut
        }

        try refreshCurrentSessionOrThrow()
    }

    @MainActor
    func refreshCurrentSession() {
        do {
            try refreshCurrentSessionOrThrow()
        } catch {
            logger.error(
                "Unable to refresh current user session",
                metadata: ["error": .string(error.localizedDescription)]
            )
            updateCurrentSession(with: nil)
        }
    }

    @MainActor
    func refreshCurrentSessionOrThrow() throws {
        try updateCurrentSession(with: resolveStoredSession())
    }

    @MainActor
    func signIn(userID: String) throws {
        Defaults[.lastSignedInUserID] = .signedIn(userID: userID)
        try refreshCurrentSessionOrThrow()
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
    func stopActivePlayback() async {
        guard let mediaPlayerManager, mediaPlayerManager.state != .stopped else { return }
        await mediaPlayerManager.stop()
        self.mediaPlayerManager = nil
    }

    @MainActor
    func scheduleServerConnectionResolution() {
        currentSession?.serverConnectionManager.scheduleConnectionResolution()
    }

    @MainActor
    func handleOpenURL(
        _ url: URL,
        authenticationAction: LocalUserAuthenticationAction?
    ) async {
        guard let deepLink = DeepLinkHandler.DeepLink(url) else { return }

        do {
            let target = try deepLinkHandler.sessionTarget(for: deepLink)
            let currentSession = currentSession
            let isSameUserSession = currentSession?.server.id == target.server.id && currentSession?.user.id == target.user.id

            if !isSameUserSession {
                try await deepLinkHandler.authenticate(
                    user: target.user,
                    authenticationAction: authenticationAction
                )

                if hasActivePlayback {
                    await stopActivePlayback()
                }

                try signIn(userID: target.user.id)
            }

            deepLinkHandler.pendingDeepLink = deepLink
        } catch {
            logger.error(
                "Failed to process deep link",
                metadata: ["error": .string(error.localizedDescription)]
            )
        }
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

    @MainActor
    private func refreshServerInformationIfNeeded(reason: ServerInformationRefreshReason) async {
        guard let currentSession else { return }

        switch reason {
        case .explicitSignIn:
            break
        case .stale:
            guard serverInformationRefreshPolicy.isStale(
                since: Defaults[.lastServerInformationRefreshDate]
            ) else { return }
        }

        do {
            try await currentSession.server.updateServerInfo()

            let response = try await currentSession.client.send(Paths.getCurrentUser)
            currentSession.user.data = response.value

            Defaults[.lastServerInformationRefreshDate] = Date.now
        } catch {
            logger.error(
                "Unable to refresh server and user information",
                metadata: ["error": .string(error.localizedDescription)]
            )
        }
    }

    private func observeMediaPlayerManager() {
        Container.shared.mediaPlayerManagerPublisher()
            .sink { [weak self] manager in
                Task { @MainActor in
                    self?.mediaPlayerManager = manager
                }
            }
            .store(in: &cancellables)
    }

    private func observeAppLifecycle() {
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
    }

    @MainActor
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
