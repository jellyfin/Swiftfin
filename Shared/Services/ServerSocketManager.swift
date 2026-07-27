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
import os

final class ServerSocketManager {

    private struct State {
        var session: JellyfinSocket.Session?
        var subscriptions: [JellyfinSocket.Subscription: (delay: Duration, interval: Duration, count: Int)] = [:]
        var reconnectRequested = false
    }

    let isConnected = CurrentValueSubject<Bool, Never>(false)

    var events: AnyPublisher<JellyfinSocket.Session.Event, Never> {
        allEvents
            .filter { !$0.isSubscription }
            .eraseToAnyPublisher()
    }

    private let logger = Logger.swiftfin()

    private let allEvents = PassthroughSubject<JellyfinSocket.Session.Event, Never>()
    private let state = OSAllocatedUnfairLock(initialState: State())
    private let wakeStream: AsyncStream<Void>
    private let wake: AsyncStream<Void>.Continuation

    private var tasks: [Task<Void, Never>] = []

    private weak var userSession: UserSession?

    init() {
        (wakeStream, wake) = AsyncStream<Void>.makeStream()
    }

    deinit {
        stop()
        wake.finish()
    }

    private func start() {
        tasks = [
            Task { [weak self] in await self?.runConnection() },
            Task { [weak self] in await self?.observeServerConnectionChange() },
        ]
    }

    private func stop() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        killSession()
    }

    private func reconnect() {
        state.withLock { $0.reconnectRequested = true }
        killSession()
        wake.yield()
    }

    /// Subscribe the socket to a high volume subscription (E.G. Activities, Sessions, etc.).
    /// Releasing the cancellable unsubscribes the socket from that subscription.
    func subscribe(
        _ subscription: JellyfinSocket.Subscription,
        delay: Duration,
        interval: Duration
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

    private func killSession() {
        state.withLock { $0.session }?.disconnect()
    }

    private static let minimumReconnectDelay: Duration = .seconds(2)
    private static let maximumReconnectDelay: Duration = .seconds(30)

    private func runConnection() async {
        var wakeIterator = wakeStream.makeAsyncIterator()
        var reconnectDelay = Self.minimumReconnectDelay

        while !Task.isCancelled {
            guard let userSession else { break }

            let session = userSession.client.socket(
                supportsMediaControl: true,
                supportedCommands: [
                    .displayMessage,
                    .playState,
                    .setAudioStreamIndex,
                    .setMaxStreamingBitrate,
                    .setSubtitleStreamIndex,
                ],
                playableMediaTypes: [.video]
            )
            .connect(
                reconnectAttempts: 1,
                reconnectDelay: .seconds(1),
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
                        logger.info("Socket connected", metadata: ["url": .stringConvertible(url)])
                        reconnectDelay = Self.minimumReconnectDelay
                        isConnected.send(true)
                    case let .message(message):
                        logger.debug("Socket message", metadata: ["message": .string("\(message)")])
                    }
                    allEvents.send(event)
                }
            } catch {
                logger.debug("Socket error: \(error.localizedDescription)")
            }

            let explicit = state.withLock { state -> Bool in
                state.session = nil
                defer { state.reconnectRequested = false }
                return state.reconnectRequested
            }

            isConnected.send(false)
            logger.info("Socket disconnected")

            if explicit {
                logger.debug("Socket reconnecting")
                reconnectDelay = Self.minimumReconnectDelay
                _ = await wakeIterator.next()
            } else {
                logger.debug("Socket lost, reconnecting in \(reconnectDelay)")
                try? await Task.sleep(for: reconnectDelay)
                reconnectDelay = min(reconnectDelay * 2, Self.maximumReconnectDelay)
            }
        }
    }

    private func observeServerConnectionChange() async {
        for await _ in Notifications[.didChangeServerConnection].publisher.values {
            logger.debug("Reconnecting the socket (Server Connection Changed)")
            reconnect()
        }
    }
}

extension ServerSocketManager: UserSessionService {

    func willStart(userSession: UserSession) async {
        self.userSession = userSession
    }

    func didStart(userSession: UserSession) {
        start()
    }

    func willStop(userSession: UserSession) {
        stop()
    }
}

// MARK: - Playback Commands

extension ServerSocketManager {

    var generalCommands: AnyPublisher<GeneralCommand, Never> {
        commands { event in
            guard case let .message(.generalCommandMessage(message)) = event else { return nil }
            return message.data
        }
    }

    var playstateCommands: AnyPublisher<PlaystateRequest, Never> {
        commands { event in
            guard case let .message(.playstateMessage(message)) = event else { return nil }
            return message.data
        }
    }

    private func commands<Command>(
        extract: @escaping (JellyfinSocket.Session.Event) -> Command?
    ) -> AnyPublisher<Command, Never> {
        events
            .compactMap(extract)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Convenience Subscription Publishers

extension ServerSocketManager {

    func sessions(
        delay: Duration = .seconds(2),
        interval: Duration = .seconds(2)
    ) -> AnyPublisher<[SessionInfoDto], Never> {
        publisher(for: .sessions, delay: delay, interval: interval) { event in
            guard case let .message(.sessionsMessage(message)) = event else { return nil }
            return message.data
        }
    }

    func activityLog(
        delay: Duration = .seconds(0),
        interval: Duration = .seconds(5)
    ) -> AnyPublisher<[ActivityLogEntry], Never> {
        publisher(for: .activityLog, delay: delay, interval: interval) { event in
            guard case let .message(.activityLogEntryMessage(message)) = event else { return nil }
            return message.data
        }
    }

    func scheduledTasks(
        delay: Duration = .seconds(0),
        interval: Duration = .seconds(5)
    ) -> AnyPublisher<[TaskInfo], Never> {
        publisher(for: .scheduledTasks, delay: delay, interval: interval) { event in
            guard case let .message(.scheduledTasksInfoMessage(message)) = event else { return nil }
            return message.data
        }
    }

    private func publisher<Payload>(
        for subscription: JellyfinSocket.Subscription,
        delay: Duration,
        interval: Duration,
        extract: @escaping (JellyfinSocket.Session.Event) -> Payload?
    ) -> AnyPublisher<Payload, Never> {
        Deferred { [weak self] () -> AnyPublisher<Payload, Never> in
            guard let self else {
                return Combine.Empty<Payload, Never>().eraseToAnyPublisher()
            }

            let token = self.subscribe(subscription, delay: delay, interval: interval)

            return self.allEvents
                .filter(\.isSubscription)
                .compactMap(extract)
                .handleEvents(receiveCancel: token.cancel)
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
