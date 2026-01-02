//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import Get
import JellyfinAPI
import UIKit

extension JellyfinClient {

    func fullURL<T>(with request: Request<T>, queryAPIKey: Bool = false) -> URL? {

        guard let path = request.url?.path else { return configuration.url }
        guard let fullPath = fullURL(with: path) else { return nil }
        guard var components = URLComponents(string: fullPath.absoluteString) else { return nil }

        components.queryItems = request.query?.map { URLQueryItem(name: $0.0, value: $0.1) } ?? []

        if queryAPIKey, let accessToken {
            components.queryItems?.append(.init(name: "api_key", value: accessToken))
        }

        return components.url ?? fullPath
    }

    /// Appends the path to the current configuration `URL`, assuming that the path begins with a leading `/`.
    /// Returns `nil` if the new `URL` is malformed.
    func fullURL(with path: String) -> URL? {
        let fullPath = configuration.url.absoluteString.trimmingCharacters(in: ["/"]) + path
        return URL(string: fullPath)
    }
}

extension JellyfinClient.Configuration {

    static func swiftfinConfiguration(
        url: URL,
        accessToken: String? = nil
    ) -> Self {

        let client = "Swiftfin \(UIDevice.platform)"
        let deviceName = UIDevice.current.name
            .folding(options: .diacriticInsensitive, locale: .current)
            .unicodeScalars
            .filter { CharacterSet.urlQueryAllowed.contains($0) }
            .description
        let deviceID = "\(UIDevice.platform)_\(UIDevice.vendorUUIDString)"
        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.1"

        return .init(
            url: url,
            accessToken: accessToken,
            client: client,
            deviceName: deviceName,
            deviceID: deviceID,
            version: version
        )
    }
}
