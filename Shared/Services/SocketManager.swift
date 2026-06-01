//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import Logging
import Network
import os
import UIKit

final class SocketManager {

    /// Published socket events
    let events = PassthroughSubject<JellyfinSocket.Session.Event, Never>()
    /// Published convenience for tracking if the socket is connected
    let isConnected = CurrentValueSubject<Bool, Never>(false)

    private struct State {
        var session: JellyfinSocket.Session?
        var subscriptions: [JellyfinSocket.Subscription: (delay: Duration, interval: Duration)] = [:]
    }

    private let logger = Logger.swiftfin()
    private let socket: JellyfinSocket

    private var tasks: [Task<Void, Never>] = []

    /// Thread-safe guard for `session` and `subscriptions`, because they are touched outside the main thread
    private let state = OSAllocatedUnfairLock(initialState: State())

    /// Signals the `runConnection` loop to start a new connection
    private let wakeStream: AsyncStream<Void>
    private let wake: AsyncStream<Void>.Continuation

    init(_ socket: JellyfinSocket) {
        self.socket = socket
        (wakeStream, wake) = AsyncStream<Void>.makeStream()
        tasks = [
            Task { [weak self] in await self?.runConnection() },
            Task { [weak self] in await self?.observeForeground() },
            Task { [weak self] in await self?.observeNetworkPath() },
        ]
    }

    deinit {
        tasks.forEach { $0.cancel() }
        wake.finish()
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
        let session = state.withLock { state in
            state.subscriptions[subscription] = (delay, interval)
            return state.session
        }

        if let session {
            session.subscribe(subscription, delay: delay, interval: interval)
        } else {
            wake.yield()
        }

        return AnyCancellable { [weak self] in
            let session = self?.state.withLock { state in
                state.subscriptions[subscription] = nil
                return state.session
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
            let session = socket.connect(
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

            logger.debug("Connecting the socket (Initial Startup)")

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

    /// Reconnect when network transitions from unreachable to reachable.
    /// Restarts the socket when switching networks (E.G. WiFI to Cellular).
    private func observeNetworkPath() async {
        let monitor = NWPathMonitor()
        defer { monitor.cancel() }

        let stream = AsyncStream<NWPath> {
            continuation in monitor.pathUpdateHandler = { continuation.yield($0) }
        }

        monitor.start(queue: .global(qos: .utility))

        var previous: NWPath.Status?

        for await path in stream {
            if path.status == .satisfied, previous == .unsatisfied {
                logger.debug("Reconnecting the socket (Network Restored)")
                reconnect()
            }
            previous = path.status
        }
    }
}
