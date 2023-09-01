//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import Get
import JellyfinAPI

extension JellyfinClient {

    func fullURL<T>(with request: Request<T>) -> URL {
        let fullPath = configuration.url.appendingPathComponent(request.url?.path ?? "")

        var components = URLComponents(string: fullPath.absoluteString)!
        components.queryItems = request.query?.map { URLQueryItem(name: $0.0, value: $0.1) } ?? []

        return components.url ?? fullPath
    }

    func fullURL(with path: String) -> URL {
        URL(string: configuration.url.absoluteString + path)!
    }
}
