//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Logging

extension Container {
    var notificationHandlers: Factory<NotificationHandlers> {
        self { NotificationHandlers() }.singleton
    }
}

protocol NotificationHandler {
    func register(with handler: NotificationHandlers)
}

actor ActiveOperationsManager {
    private var activeOperations = Set<String>()

    func contains(_ key: String) -> Bool {
        activeOperations.contains(key)
    }

    func insert(_ key: String) {
        activeOperations.insert(key)
    }

    func remove(_ key: String) {
        activeOperations.remove(key)
    }

    var count: Int {
        activeOperations.count
    }
}

final class NotificationHandlers: ObservableObject {

    // MARK: - Logger

    let logger = Logger.swiftfin()

    // MARK: - Shared Properties

    var cancellables = Set<AnyCancellable>()
    private let activeOperationsManager = ActiveOperationsManager()

    // MARK: - Notification Handlers

    private lazy var notificationHandlers: [NotificationHandler] = [
        ItemNotificationHandler(),
    ]

    // MARK: - Initialization

    init() {
        registerHandlerSubscriptions()
    }

    // MARK: - Register All Notification Handlers

    private func registerHandlerSubscriptions() {
        logger.info("Registering Notification Handlers: \(notificationHandlers.count)")

        /// Register all Notification Handlers
        for handler in notificationHandlers {
            handler.register(with: self)
            logger.debug("Registered Notification Handler: \(type(of: handler))")
        }
    }

    // MARK: - Execute Operation

    func executeOperation<T>(
        key: String,
        operation: () async throws -> T
    ) async -> T? {

        if await activeOperationsManager.contains(key) {
            logger.info("Skipping Duplicate Notification: \(key)")
            return nil
        }

        await activeOperationsManager.insert(key)
        logger.info("Starting Notification: \(key)")

        defer {
            Task {
                await activeOperationsManager.remove(key)
                let queueCount = await activeOperationsManager.count
                logger.info("Notification Completed: \(key)")
                logger.info("Notifications Remaining: \(queueCount)")
            }
        }

        do {
            let result = try await operation()
            logger.debug("Notification Succeeded: \(key)")
            return result
        } catch {
            logger.error("Notification Failed: \(key) - \(error.localizedDescription)")
            return nil
        }
    }
}
