//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import Logging

/// Manages background URL session completion handlers
final class BackgroundSessionManager {

    static let shared = BackgroundSessionManager()

    private let logger = Logger.swiftfin()
    private var completionHandlers: [String: () -> Void] = [:]
    private let queue = DispatchQueue(label: "com.swiftfin.background-session-manager", qos: .utility)

    private init() {}

    /// Store a completion handler for a background session identifier
    func storeCompletionHandler(_ completionHandler: @escaping () -> Void, for identifier: String) {
        queue.async {
            self.logger.info("Storing completion handler for background session: \(identifier)")
            self.completionHandlers[identifier] = completionHandler
        }
    }

    /// Retrieve and remove a completion handler for a background session identifier
    func retrieveCompletionHandler(for identifier: String) -> (() -> Void)? {
        queue.sync {
            let handler = completionHandlers.removeValue(forKey: identifier)
            if handler != nil {
                logger.info("Retrieved completion handler for background session: \(identifier)")
            } else {
                logger.warning("No completion handler found for background session: \(identifier)")
            }
            return handler
        }
    }

    /// Call the completion handler for a background session identifier
    func callCompletionHandler(for identifier: String) {
        queue.async {
            if let handler = self.completionHandlers.removeValue(forKey: identifier) {
                self.logger.info("Calling completion handler for background session: \(identifier)")
                DispatchQueue.main.async {
                    handler()
                }
            } else {
                self.logger.warning("No completion handler found to call for background session: \(identifier)")
            }
        }
    }
}
