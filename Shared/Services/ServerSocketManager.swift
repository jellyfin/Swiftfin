//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI
import Logging
import os
import UIKit

final class ServerSocketManager {

    /// Published socket events
    let events = PassthroughSubject<JellyfinSocket.Session.Event, Never>()
    /// Published convenience for tracking if the socket is connected
    let isConnected = CurrentValueSubject<Bool, Never>(false)

    private struct State {
        var session: JellyfinSocket.Session?
        var subscriptions: [JellyfinSocket.Subscription: (delay: Duration, interval: Duration, count: Int)] = [:]
    }

    private let logger = Logger.swiftfin()
    private let userSession: UserSession

    private var tasks: [Task<Void, Never>] = []

    /// Thread-safe guard for `session` and `subscriptions`, because they are touched outside the main thread
    private let state = OSAllocatedUnfairLock(initialState: State())

    /// Signals the `runConnection` loop to start a new connection
    private let wakeStream: AsyncStream<Void>
    private let wake: AsyncStream<Void>.Continuation

    init(userSession: UserSession) {
        self.userSession = userSession
        (wakeStream, wake) = AsyncStream<Void>.makeStream()
    }

    deinit {
        stop()
        wake.finish()
    }

    private func start() {
        tasks = [
            Task { [weak self] in await self?.runConnection() },
            Task { [weak self] in await self?.observeForeground() },
            Task { [weak self] in await self?.observeNetworkChange() },
        ]
    }

    private func stop() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        killSession()
    }

    /// Drop the current session and start a new one.
    func reconnect() {
        killSession()
        wake.yield()
    }

    /// Subscribe the socket to a high volume subscription (E.G. Activities, Sessions, etc.).
    /// Releasing the cancellable unsubscribes the socket from that subscription.
    func subscribe(
        _ subscription: JellyfinSocket.Subscription,
        delay: Duration = .seconds(0),
        interval: Duration = .seconds(5)
    ) -> AnyCancellable {
        let (session, effectiveDelay, effectiveInterval) = state.withLock { state -> (JellyfinSocket.Session?, Duration, Duration) in
            let existing = state.subscriptions[subscription]
            let effectiveDelay = min(existing?.delay ?? delay, delay)
            let effectiveInterval = min(existing?.interval ?? interval, interval)
            let count = (existing?.count ?? 0) + 1

            state.subscriptions[subscription] = (effectiveDelay, effectiveInterval, count)
            return (state.session, effectiveDelay, effectiveInterval)
        }

        if let session {
            session.subscribe(subscription, delay: effectiveDelay, interval: effectiveInterval)
        } else {
            wake.yield()
        }

        return AnyCancellable { [weak self] in
            let session = self?.state.withLock { state -> JellyfinSocket.Session? in
                guard let existing = state.subscriptions[subscription] else { return nil }

                if existing.count <= 1 {
                    state.subscriptions[subscription] = nil
                    return state.session
                }

                state.subscriptions[subscription] = (existing.delay, existing.interval, existing.count - 1)
                return nil
            }
            session?.unsubscribe(subscription)
        }
    }

    /// Disconnect the current session if one exists.
    private func killSession() {
        state.withLock { $0.session }?.disconnect()
    }

    /// Connects to the socket and publish events for multiple consumers.
    /// This will attempt to reconnect the socket if it goes offline.
    private func runConnection() async {
        var wakeIterator = wakeStream.makeAsyncIterator()

        while !Task.isCancelled {
            let session = userSession.client.socket(
                supportsMediaControl: false,
                supportedCommands: [.displayMessage],
                playableMediaTypes: [.video]
            )
            .connect(
                reconnectAttempts: 5,
                reconnectDelay: .seconds(2),
                responseTimeout: .seconds(10)
            )

            let subscriptions = state.withLock { state in
                state.session = session
                return state.subscriptions
            }
            for subscription in subscriptions {
                session.subscribe(
                    subscription.key,
                    delay: subscription.value.delay,
                    interval: subscription.value.interval
                )
            }

            logger.debug("Connecting the socket")

            do {
                for try await event in session.events {
                    switch event {
                    case .connecting:
                        logger.debug("Socket retrying...")
                    case let .connected(url):
                        logger.info("Socket connected to \(url)!")
                        isConnected.send(true)
                    case let .message(message):
                        logger.debug("Socket message: \(message)")
                    }
                    events.send(event)
                }
            } catch {
                logger.debug("Socket error: \(error.localizedDescription)")
            }

            state.withLock { $0.session = nil }
            isConnected.send(false)
            logger.info("Socket disconnected")
            logger.debug("Socket waiting for signal")
            _ = await wakeIterator.next()
            logger.debug("Socket wake received")
        }
    }

    /// Reconnect when the app returns to the foreground.
    /// Fixes the socket when it expires in the background.
    private func observeForeground() async {
        for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
            logger.debug("Reconnecting the socket (Background -> Foreground)")
            reconnect()
        }
    }

    /// Reconnect when `ServerConnectionManager` reports the network path changed
    /// Fixes the socket to send responses to the right IP if new.
    private func observeNetworkChange() async {
        for await _ in Notifications[.didChangeNetwork].publisher.values {
            logger.debug("Reconnecting the socket (Network Changed)")
            reconnect()
        }
    }
}

extension ServerSocketManager: UserSessionService {

    @MainActor
    func userSessionDidStart() {
        start()
    }

    @MainActor
    func userSessionWillStop() {
        stop()
    }
}

// MARK: - Convenience Subscription Publishers

extension ServerSocketManager {

    static func sessions(
        delay: Duration = .seconds(2),
        interval: Duration = .seconds(2)
    ) -> AnyPublisher<[SessionInfoDto], Never> {
        publisher(for: .sessions, delay: delay, interval: interval) { event in
            guard case let .message(.sessionsMessage(message)) = event else { return nil }
            return message.data
        }
    }

    static func activityLog(
        delay: Duration = .seconds(0),
        interval: Duration = .seconds(5)
    ) -> AnyPublisher<[ActivityLogEntry], Never> {
        publisher(for: .activityLog, delay: delay, interval: interval) { event in
            guard case let .message(.activityLogEntryMessage(message)) = event else { return nil }
            return message.data
        }
    }

    static func scheduledTasks(
        delay: Duration = .seconds(0),
        interval: Duration = .seconds(5)
    ) -> AnyPublisher<[TaskInfo], Never> {
        publisher(for: .scheduledTasks, delay: delay, interval: interval) { event in
            guard case let .message(.scheduledTasksInfoMessage(message)) = event else { return nil }
            return message.data
        }
    }

    private static func publisher<Payload>(
        for subscription: JellyfinSocket.Subscription,
        delay: Duration,
        interval: Duration,
        extract: @escaping (JellyfinSocket.Session.Event) -> Payload?
    ) -> AnyPublisher<Payload, Never> {
        Publishers.Merge(
            Notifications[.didChangeUserSession].publisher,
            Notifications[.applicationWillEnterForeground].publisher
        )
        .prepend(())
        .map { _ -> AnyPublisher<Payload, Never> in
            guard let socket = Container.shared.currentUserSession()?.serverSocketManager else {
                return Empty().eraseToAnyPublisher()
            }

            let token = socket.subscribe(subscription, delay: delay, interval: interval)

            return socket.events
                .compactMap(extract)
                .handleEvents(receiveCancel: token.cancel)
                .eraseToAnyPublisher()
        }
        .switchToLatest()
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
