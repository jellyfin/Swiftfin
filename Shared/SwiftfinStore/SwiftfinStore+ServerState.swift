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

        @available(*, deprecated, message: "Don't use sample states")
        static var sample: Server {
            .init(
                urls: [
                    .init(string: "http://localhost:8096")!,
                ],
                currentURL: .init(string: "http://localhost:8096")!,
                name: "Johnny's Tree",
                id: "123abc",
                usersIDs: ["1", "2"]
            )
        }

        var client: JellyfinClient {
            JellyfinClient(
                configuration: .swiftfinConfiguration(url: currentURL),
                sessionDelegate: URLSessionProxyDelegate(logger: LogManager.pulseNetworkLogger())
            )
        }
    }
}
