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

    typealias Topic = JellyfinSocket.Subscription

    let events = PassthroughSubject<JellyfinSocket.Session.Event, Never>()
    let isConnected = CurrentValueSubject<Bool, Never>(false)

    private struct State {
        var session: JellyfinSocket.Session?
        var subscriptions: [Topic: (delay: Duration, interval: Duration)] = [:]
    }

    private let logger = Logger.swiftfin()
    private let socket: JellyfinSocket

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let wakeStream: AsyncStream<Void>
    private let wake: AsyncStream<Void>.Continuation

    private var tasks: [Task<Void, Never>] = []

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

    /// Subscribe to a subscription. Releasing the cancellable unsubscribes.
    func subscribe(_ topic: Topic, delay: Duration = .seconds(0), interval: Duration = .seconds(5)) -> AnyCancellable {
        let session = state.withLock { state in
            state.subscriptions[topic] = (delay, interval)
            return state.session
        }

        if let session {
            session.subscribe(topic, delay: delay, interval: interval)
        } else {
            wake.yield()
        }

        return AnyCancellable { [weak self] in
            let session = self?.state.withLock { state in
                state.subscriptions[topic] = nil
                return state.session
            }
            session?.unsubscribe(topic)
        }
    }

    /// Disconnect the current session if one exists.
    private func killSession() {
        state.withLock { $0.session }?.disconnect()
    }

    /// Bridge session events into multi-usable publishers, re-apply subscriptions on each connect, and park between sessions until
    /// signaled.
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

            logger.debug("Socket connecting")

            do {
                for try await event in session.events {
                    switch event {
                    case .connecting:
                        logger.debug("Socket retrying")
                    case let .connected(url):
                        logger.info("Socket connected to \(url)")
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
    private func observeForeground() async {
        for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
            logger.debug("Socket reconnect: foreground")
            reconnect()
        }
    }

    /// Reconnect when network transitions from unreachable to reachable.
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
                logger.debug("Socket reconnect: network restored")
                reconnect()
            }
            previous = path.status
        }
    }
}
