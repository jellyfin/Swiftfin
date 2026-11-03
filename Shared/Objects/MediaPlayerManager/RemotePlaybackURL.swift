//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum RemotePlaybackURL {

    /// Receivers fetch media themselves and cannot use the sender's HTTP headers.
    /// Call only with URLs resolved against the authenticated Jellyfin server.
    static func authenticated(_ url: URL, accessToken: String?) -> URL? {
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

        let hasToken = components.queryItems?.contains {
            ["api_key", "apikey"].contains($0.name.lowercased()) && $0.value?.isEmpty == false
        } == true

        if !hasToken, let accessToken {
            components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "ApiKey", value: accessToken)]
        }

        return components.url
    }
}
