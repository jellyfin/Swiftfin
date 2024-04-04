//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import Get
import JellyfinAPI

extension JellyfinClient {

    func fullURL<T>(with request: Request<T>) -> URL? {

        guard let path = request.url?.path else { return configuration.url }
        guard let fullPath = fullURL(with: path) else { return nil }

        var components = URLComponents(string: fullPath.absoluteString)!
        components.queryItems = request.query?.map { URLQueryItem(name: $0.0, value: $0.1) } ?? []

        return components.url ?? fullPath
    }

    /// Appends the path to the current configuration `URL`, assuming that the path begins with a leading `/`.
    /// Returns `nil` if the new `URL` is malformed.
    func fullURL(with path: String) -> URL? {
        guard let fullPath = URL(string: configuration.url.absoluteString.trimmingCharacters(in: ["/"]) + path)
        else { return nil }
        return fullPath
    }
}
