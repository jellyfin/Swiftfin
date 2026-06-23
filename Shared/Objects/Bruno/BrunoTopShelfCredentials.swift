//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// MARK: - BrunoTopShelfCredentials

//
// The cross-process bridge for the system Top Shelf extension (roadmap §1b). The Top Shelf
// provider runs in its OWN process, so it can't read the app's keychain/session directly — the
// main app writes the minimum it needs (server URL + token + user id) into a shared App Group
// container here, and the extension reads it back with `load()`.
//
// This is intentionally dependency-free (Foundation only) so the exact same file can be compiled
// into BOTH the app and the lightweight extension target without dragging in JellyfinAPI.
//
// IMPORTANT: until the App Group capability (`appGroupID`) is added to both targets, `save()`
// and `load()` are silent no-ops (UserDefaults(suiteName:) returns nil) — so wiring this into the
// app's session start is harmless before the extension target exists. See docs/TOP_SHELF_SETUP.md.
struct BrunoTopShelfCredentials: Codable, Equatable {

    let serverURL: URL
    let accessToken: String
    let userID: String
    /// Jellyfin server id — required to build a deep link the app's DeepLinkHandler accepts.
    let serverID: String

    /// MUST match the App Group capability added to the app **and** the Top Shelf extension.
    static let appGroupID = "group.com.diplomacymusic.bruno"

    private static let defaultsKey = "bruno.topShelf.credentials"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Called by the app when a user session is active. No-op if the token is empty or the App
    /// Group isn't configured yet.
    static func save(serverURL: URL, accessToken: String, userID: String, serverID: String) {
        guard !accessToken.isEmpty else { return }

        let credentials = BrunoTopShelfCredentials(
            serverURL: serverURL,
            accessToken: accessToken,
            userID: userID,
            serverID: serverID
        )

        guard let defaults = sharedDefaults,
              let data = try? JSONEncoder().encode(credentials)
        else { return }

        defaults.set(data, forKey: defaultsKey)
    }

    /// Deep link the app's DeepLinkHandler accepts: `swiftfin://<serverID>/<userID>/item/<id>`.
    /// The `swiftfin` scheme + this exact shape are already registered/handled, so the Top Shelf
    /// needs no new scheme or parser.
    func itemDeepLink(itemID: String) -> URL? {
        URL(string: "swiftfin://\(serverID)/\(userID)/item/\(itemID)")
    }

    /// Called by the Top Shelf extension. Returns nil when there's no signed-in session to show.
    static func load() -> BrunoTopShelfCredentials? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: defaultsKey),
              let credentials = try? JSONDecoder().decode(BrunoTopShelfCredentials.self, from: data)
        else { return nil }

        return credentials
    }

    /// Called by the app on sign-out so the Top Shelf falls back to the static `BRUNO.` image.
    static func clear() {
        sharedDefaults?.removeObject(forKey: defaultsKey)
    }
}
