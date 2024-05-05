//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Pulse

extension SwiftfinStore.State {

    struct Server: Hashable, Identifiable {

        let urls: Set<URL>
        let currentURL: URL
        let name: String
        let id: String
        let userIDs: [String]

        init(
            urls: Set<URL>,
            currentURL: URL,
            name: String,
            id: String,
            usersIDs: [String]
        ) {
            self.urls = urls
            self.currentURL = currentURL
            self.name = name
            self.id = id
            self.userIDs = usersIDs
        }

        /// - Note: Since this is created from a server, it does not
        ///         have a user access token.
        var client: JellyfinClient {
            JellyfinClient(
                configuration: .swiftfinConfiguration(url: currentURL),
                sessionDelegate: URLSessionProxyDelegate(logger: LogManager.pulseNetworkLogger())
            )
        }
    }
}

extension ServerState {

    func getSystemInfo() async throws -> (public: PublicSystemInfo, info: SystemInfo) {
        let publicInfoRequest = Paths.getPublicSystemInfo
        let systemInfoRequest = Paths.getSystemInfo

        async let publicInfoResponse = client.send(publicInfoRequest)
        async let systemInfoResponse = client.send(systemInfoRequest)

        return try await (public: publicInfoResponse.value, info: systemInfoResponse.value)
    }

    func splashScreenImageSource() -> ImageSource {
        let request = Paths.getSplashscreen()
        return ImageSource(url: client.fullURL(with: request))
    }
}
