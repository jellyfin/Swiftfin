//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if DEBUG
import Defaults
import Factory
import Foundation
import Get
import JellyfinAPI
import Pulse

// MARK: - BrunoAutoSignIn (DEBUG only)

//
// Headless sign-in for autonomous verification: with no UI typing, replicate exactly what
// `ConnectToServerViewModel` + `UserSignInViewModel` do on a real sign-in — create the server
// + user `StoredValues` records, authenticate via the SDK, and write the access token to the
// keychain — then ask `UserSessionManager` to resolve the session. This is purely a test hook:
// it calls the app's OWN sign-in primitives (no auth-flow code is modified) and is gated behind
// `BRUNO_AUTOSIGNIN=1`, with credentials supplied at launch via `JF_BASE`/`JF_USER_NAME`/`JF_PASS`
// env vars (never compiled in). Because the token round-trips through the same keychain path the
// stock app uses, a clean relaunch afterwards also proves whether the (ad-hoc) signing persists it.
enum BrunoAutoSignIn {

    static var isRequested: Bool {
        ProcessInfo.processInfo.environment["BRUNO_AUTOSIGNIN"] == "1"
    }

    @MainActor
    static func runIfRequested() async {
        guard isRequested else { return }

        // Already signed in (e.g. a relaunch after a previous auto-sign-in) — leave it be so the
        // relaunch genuinely exercises `resolveCurrentSession` reading the persisted keychain token.
        if case .signedIn = Defaults[.lastSignedInUserID] {
            log("already signed in — relaunch is exercising persisted session")
            return
        }

        let env = ProcessInfo.processInfo.environment
        guard let urlString = env["JF_BASE"],
              let username = env["JF_USER_NAME"],
              let password = env["JF_PASS"],
              let url = URL(string: urlString)
        else {
            log("missing JF_BASE / JF_USER_NAME / JF_PASS env")
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
                log("public system info missing name/id")
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
                log("authenticate response missing token/user")
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

            user.accessToken = accessToken // keychain write — the line whose persistence we're testing
            user.data = userData

            // 4. Resolve the session (mirrors UserSessionManager.signIn).
            Container.shared.userSessionManager().signIn(userID: userID)
            log("SIGNED IN userID=\(userID) tokenLen=\(accessToken.count) server=\(serverName)")
        } catch {
            log("ERROR \(error)")
        }
    }

    /// Append a line to a file in the app container (pull via `simctl get_app_container … data`)
    /// and echo to stdout so it shows in `simctl launch --console`.
    private static func log(_ message: String) {
        let line = "BRUNO_AUTOSIGNIN: \(message)"
        print(line)
        let path = (NSHomeDirectory() as NSString).appendingPathComponent("Documents/bruno-autosignin.log")
        let data = Data((line + "\n").utf8)
        if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: path)) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }
}
#endif
