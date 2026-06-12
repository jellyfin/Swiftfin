//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Foundation
import Logging

final class UserSessionManager {

    enum SignOutReason {
        case backgroundTimeout
        case close
        case deepLinkUserSwitch
        case explicit
        case invalidStoredSession
    }

    private let logger = Logger.swiftfin()
    private var mediaPlayerManager: MediaPlayerManager?
    private var cancellables = Set<AnyCancellable>()

    private(set) var currentSession: UserSession?

    @MainActor
    var hasActivePlayback: Bool {
        guard let mediaPlayerManager else { return false }
        return mediaPlayerManager.state != .stopped
    }

    init() {
        handleAppLaunch()
        currentSession = Self.resolveCurrentSession()
        observeAppLifecycle()
    }

    func refreshCurrentSession() {
        currentSession = Self.resolveCurrentSession()
        Container.shared.currentUserSession.reset()
    }

    func signIn(userID: String) {
        Defaults[.lastSignedInUserID] = .signedIn(userID: userID)
        refreshCurrentSession()
        Notifications[.didSignIn].post()
    }

    func signOut(reason: SignOutReason) {
        Defaults[.lastSignedInUserID] = .signedOut
        refreshCurrentSession()

        logger.info(
            "Signed out current user",
            metadata: ["reason": .stringConvertible(String(describing: reason))]
        )

        Notifications[.didSignOut].post()
    }

    private func handleAppLaunch() {
        guard Defaults[.signOutOnClose] else { return }
        Defaults[.lastSignedInUserID] = .signedOut
    }

    @MainActor
    func setActiveMediaPlayerManager(_ manager: MediaPlayerManager?) {
        mediaPlayerManager = manager
    }

    @MainActor
    func stopActivePlayback() async {
        guard let mediaPlayerManager, mediaPlayerManager.state != .stopped else { return }
        await mediaPlayerManager.stop()
        self.mediaPlayerManager = nil
    }

    func appDidEnterBackground() {
        Defaults[.backgroundTimeStamp] = Date.now
    }

    @MainActor
    func appWillEnterForeground() {
        refreshCurrentSession()

        guard currentSession != nil else { return }
        guard Defaults[.signOutOnBackground] else { return }
        guard !hasActivePlayback else { return }

        let backgroundedInterval = Date.now.timeIntervalSince(Defaults[.backgroundTimeStamp])
        guard backgroundedInterval > Defaults[.backgroundSignOutInterval] else { return }

        signOut(reason: .backgroundTimeout)
    }

    private func observeAppLifecycle() {
        Notifications[.applicationDidEnterBackground]
            .publisher
            .sink { [weak self] in
                self?.appDidEnterBackground()
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

    private static func resolveCurrentSession() -> UserSession? {
        guard case let .signedIn(userId) = Defaults[.lastSignedInUserID] else { return nil }

        guard let user = StoredValues[.User.users].first(where: { $0.id == userId }) else {
            Defaults[.lastSignedInUserID] = .signedOut
            return nil
        }

        guard let server = StoredValues[.Server.servers].first(where: { $0.id == user.serverID }) else {
            Defaults[.lastSignedInUserID] = .signedOut
            return nil
        }

        return .init(
            server: server,
            user: user
        )
    }
}

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
