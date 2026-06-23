//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import Get
import JellyfinAPI
import Logging
import Pulse

// MARK: - BrunoDevAutoLogin

//
// DEV CONVENIENCE — hardcoded auto-login for the owner's home server so a FRESH INSTALL skips the
// entire connect / sign-in onboarding and lands straight in the app. App updates on tvOS require
// deleting + reinstalling the app (which wipes the keychain + stored session), which would
// otherwise force a from-scratch onboarding on every update; this removes that friction.
//
// It runs ONLY when there is no existing session (a clean install / signed-out state). A session
// that survives an update is used as-is and this is skipped. It calls the app's OWN sign-in
// primitives — the same path as ConnectToServerViewModel + UserSignInViewModel + UserSessionManager
// (see BrunoAutoSignIn for the DEBUG/env-var twin) — so no auth-flow code is modified.
//
// ⚠️ Credentials are compiled in. This is a personal build for a private LAN server. Set
// `isEnabled = false` (or delete this file + its one call in RootCoordinator) before sharing or
// releasing this build to anyone else.
enum BrunoDevAutoLogin {

    /// Master switch. Flip to `false` to disable hardcoded auto-login.
    static let isEnabled = true

    private static let serverURLString = "http://192.168.50.19:8899"
    private static let username = "BrunelleHouse"
    private static let password = "0710"

    private static let logger = Logger.swiftfin()

    /// Connect + sign in with the hardcoded credentials when there is no current session.
    /// Safe to call on every launch: it no-ops once a session exists.
    @MainActor
    static func runIfNeeded() async {
        guard isEnabled else { return }

        // Only auto-login from a clean / signed-out state. A session that survived an update is
        // honored as-is so we don't clobber an intentional account.
        guard Container.shared.currentUserSession() == nil else { return }
        if case .signedIn = Defaults[.lastSignedInUserID] { return }

        guard let url = URL(string: serverURLString) else {
            logger.error("BrunoDevAutoLogin: invalid server URL \(serverURLString)")
            return
        }

        do {
            // 1. Resolve the server (mirrors ConnectToServerViewModel.connectToServer).
            let probe = JellyfinClient(
                configuration: .swiftfinConfiguration(url: url),
                sessionConfiguration: .swiftfin,
                sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin())
            )
            let info = try await probe.send(Paths.getPublicSystemInfo).value
            guard let serverName = info.serverName, let serverID = info.id else {
                logger.error("BrunoDevAutoLogin: public system info missing name/id")
                return
            }

            let server = ServerState(
                urls: [url],
                currentURL: url,
                name: serverName,
                id: serverID,
                userIDs: []
            )
            StoredValues[.Server.servers] = StoredValues[.Server.servers]
                .filter { $0.id != serverID }
                .appending(server)
            StoredValues[.Server.publicInfo(id: serverID)] = info

            // 2. Authenticate (mirrors UserSignInViewModel._signIn).
            let auth = try await server.client.signIn(username: username, password: password)
            guard let accessToken = auth.accessToken,
                  let userData = auth.user,
                  let userID = userData.id,
                  let resolvedName = userData.name
            else {
                logger.error("BrunoDevAutoLogin: auth response missing token/user")
                return
            }

            // 3. Persist the user record + token (mirrors UserSignInViewModel._save).
            let user = UserState(id: userID, serverID: serverID, username: resolvedName)
            StoredValues[.User.users] = StoredValues[.User.users]
                .filter { $0.id != userID }
                .appending(user)

            var servers = StoredValues[.Server.servers]
            if let index = servers.firstIndex(where: { $0.id == serverID }) {
                let existing = servers[index]
                servers[index] = ServerState(
                    urls: existing.urls,
                    currentURL: existing.currentURL,
                    name: existing.name,
                    id: existing.id,
                    userIDs: existing.userIDs.appending(userID)
                )
                StoredValues[.Server.servers] = servers
            }

            user.accessToken = accessToken // keychain write
            user.data = userData

            // 4. Resolve the session (mirrors UserSessionManager.signIn) — posts
            //    `didChangeUserSession`, which routes RootCoordinator to the main app.
            Container.shared.userSessionManager().signIn(userID: userID)
            logger.info("BrunoDevAutoLogin: signed in as \(resolvedName) on \(serverName)")
        } catch {
            logger.error("BrunoDevAutoLogin: \(error.localizedDescription)")
        }
    }
}
