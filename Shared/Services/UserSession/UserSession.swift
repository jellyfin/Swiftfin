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
import JellyfinAPI
import Logging
import Pulse

final class UserSession {

    let client: JellyfinClient
    let server: ServerState
    let user: UserState

    init(
        server: ServerState,
        user: UserState
    ) {
        self.server = server
        self.user = user

        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(
                url: server.effectiveServerURL,
                accessToken: user.accessToken
            ),
            sessionConfiguration: .swiftfin,
            sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin())
        )

        self.client = client
    }
}

enum UserSessionError: LocalizedError {

    case missingCurrentSession

    var errorDescription: String? {
        switch self {
        case .missingCurrentSession:
            "No signed-in user session is available."
        }
    }
}
