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

    private struct Claim {
        let subscription: JellyfinSocket.Subscription
        let delay: Duration
        let interval: Duration
        var token: JellyfinSocket.Session.SubscriptionToken?
    }

    private struct State {
        var session: JellyfinSocket.Session?
        var claims: [UUID: Claim] = [:]
        var reconnectRequested = false
    }

    let isConnected = CurrentValueSubject<Bool, Never>(false)

    var events: AnyPublisher<JellyfinSocket.Session.Event, Never> {
        allEvents
            .filter { $0.subscription == nil }
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

        // Remove any existing sockets first
        stop()

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
        let id = UUID()

        let session = state.withLock { state -> JellyfinSocket.Session? in
            state.claims[id] = Claim(subscription: subscription, delay: delay, interval: interval)
            return state.session
        }

        if let session {
            let token = session.subscribe(subscription, delay: delay, interval: interval)
            state.withLock { $0.claims[id]?.token = token }
        } else {
            wake.yield()
        }

        return AnyCancellable { [weak self] in
            guard let self else { return }

            let token = state.withLock { $0.claims.removeValue(forKey: id)?.token }
            token?.cancel()
        }
    }

    private func killSession() {
        state.withLock { $0.session }?.disconnect()
    }

    private func runConnection() async {
        var wakeIterator = wakeStream.makeAsyncIterator()

        while !Task.isCancelled {
            guard let userSession else { break }

            let session = userSession.client.socket(
                supportsMediaControl: true,
                supportedCommands: [
                    .displayContent,
                    .play,
                    .playMediaSource,
                    .playState,
                    .playTrailers,
                    .setAudioStreamIndex,
                    .setMaxStreamingBitrate,
                    .setSubtitleStreamIndex,
                ],
                playableMediaTypes: [.video]
            )
            .connect(responseTimeout: .seconds(10))

            let claims = state.withLock { state in
                state.session = session
                return state.claims
            }

            for (id, claim) in claims {
                let token = session.subscribe(
                    claim.subscription,
                    delay: claim.delay,
                    interval: claim.interval
                )

                state.withLock { $0.claims[id]?.token = token }
            }

            logger.debug("Connecting the socket")

            // The session reconnects on its own, so the stream only ends on an explicit
            // disconnect or a refusal there is no point retrying.
            var wasRefused = false

            do {
                for try await event in session.events {
                    switch event {
                    case .connecting:
                        logger.debug("Socket retrying...")
                    case let .connected(url):
                        logger.info("Socket connected", metadata: ["url": .stringConvertible(url)])
                        isConnected.send(true)
                    case .disconnected:
                        logger.info("Socket disconnected")
                        isConnected.send(false)
                    case let .message(message):
                        logger.debug("Socket message", metadata: ["message": .string("\(message)")])
                    }
                    allEvents.send(event)
                }
            } catch {
                if let socketError = error as? JellyfinSocket.Session.SocketError,
                   case .unauthorized = socketError
                {
                    wasRefused = true
                }

                logger.debug("Socket error: \(error.localizedDescription)")
            }

            let (hasClaims, explicit) = state.withLock { state -> (Bool, Bool) in
                state.session = nil
                defer { state.reconnectRequested = false }
                return (state.claims.isNotEmpty, state.reconnectRequested)
            }

            isConnected.send(false)
            logger.info("Socket session ended")

            if explicit {
                logger.debug("Socket reconnecting")
                _ = await wakeIterator.next()
            } else if hasClaims, !wasRefused {
                logger.debug("Socket lost, reconnecting after backoff")
                try? await Task.sleep(for: .seconds(2))
            } else {
                logger.debug("Socket waiting for signal")
                _ = await wakeIterator.next()
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

    var playCommands: AnyPublisher<PlayRequest, Never> {
        commands { event in
            guard case let .message(.playMessage(message)) = event else { return nil }
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
                .filter { $0.subscription == subscription }
                .compactMap(extract)
                .handleEvents(receiveCancel: token.cancel)
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
