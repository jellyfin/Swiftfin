//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Pulse

private let redactedMessage = "<Redacted by Swiftfin>"

extension NetworkLogger {

    static func swiftfin() -> NetworkLogger {
        var configuration = NetworkLogger.Configuration()

        configuration.willHandleEvent = { event -> LoggerStore.Event? in
            if case var LoggerStore.Event.networkTaskCompleted(task) = event {
                guard let url = task.originalRequest.url,
                      let requestBody = task.requestBody
                else {
                    return event
                }

                let pathComponents = url.pathComponents

                if pathComponents.last == "AuthenticateByName",
                   var body = try? JSONDecoder().decode(AuthenticateUserByName.self, from: requestBody)
                {
                    body.pw = redactedMessage
                    task.requestBody = try? JSONEncoder().encode(body)

                    return LoggerStore.Event.networkTaskCompleted(task)
                }

                if pathComponents.last == "Password",
                   var body = try? JSONDecoder().decode(UpdateUserPassword.self, from: requestBody)
                {
                    body.currentPassword = redactedMessage
                    body.currentPw = redactedMessage
                    body.newPw = redactedMessage
                    body.isResetPassword = nil
                    task.requestBody = try? JSONEncoder().encode(body)

                    return LoggerStore.Event.networkTaskCompleted(task)
                }
            }

            return event
        }

        return NetworkLogger(configuration: configuration)
    }
}
