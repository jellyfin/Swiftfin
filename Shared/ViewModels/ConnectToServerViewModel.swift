//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Factory
import Foundation
import Get
import JellyfinAPI
import OrderedCollections
import Pulse

final class ConnectToServerViewModel: ViewModel, Eventful, Stateful {

    // MARK: Event

    enum Event {
        case connected(ServerState)
        case duplicateServer(ServerState)
        case error(JellyfinAPIError)
    }

    // MARK: Action

    enum Action: Equatable {
        case addNewURL(ServerState)
        case cancel
        case connect(String)
        case searchForServers
    }

    // MARK: BackgroundState

    enum BackgroundState: Hashable {
        case searching
    }

    // MARK: State

    enum State: Hashable {
        case connecting
        case initial
    }

    @Published
    var backgroundStates: OrderedSet<BackgroundState> = []

    // no longer-found servers are not cleared, but not an issue
    @Published
    var localServers: OrderedSet<ServerState> = []
    @Published
    var state: State = .initial

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var connectTask: AnyCancellable? = nil
    private let discovery = ServerDiscovery()
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    deinit {
        discovery.close()
    }

    override init() {
        super.init()

        Task { [weak self] in
            guard let self else { return }

            for await response in discovery.discoveredServers.values {
                await MainActor.run {
                    let _ = self.localServers.append(response.asServerState)
                }
            }
        }
        .store(in: &cancellables)
    }

    func respond(to action: Action) -> State {
        switch action {
        case let .addNewURL(server):
            addNewURL(server: server)

            return state
        case .cancel:
            connectTask?.cancel()

            return .initial
        case let .connect(url):
            connectTask?.cancel()

            connectTask = Task {
                do {
                    let server = try await connectToServer(url: url)

                    if isDuplicate(server: server) {
                        await MainActor.run {
                            // server has same id, but (possible) new URL
                            self.eventSubject.send(.duplicateServer(server))
                        }
                    } else {
                        try await save(server: server)

                        await MainActor.run {
                            self.eventSubject.send(.connected(server))
                        }
                    }

                    await MainActor.run {
                        self.state = .initial
                    }
                } catch is CancellationError {
                    // cancel doesn't matter
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                        self.state = .initial
                    }
                }
            }
            .asAnyCancellable()

            return .connecting
        case .searchForServers:
            discovery.broadcast()

            return state
        }
    }

    private func connectToServer(url: String) async throws -> ServerState {

        let formattedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)
            .trimmingCharacters(in: ["/"])
            .prepending("http://", if: !url.contains("://"))

        guard let url = URL(string: formattedURL) else { throw JellyfinAPIError("Invalid URL") }

        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: url),
            sessionDelegate: URLSessionProxyDelegate(logger: Container.shared.pulseNetworkLogger())
        )

        let response = try await client.send(Paths.getPublicSystemInfo)

        guard let name = response.value.serverName,
              let id = response.value.id
        else {
            logger.critical("Missing server data from network call")
            throw JellyfinAPIError("An internal error has occurred")
        }

        let connectionURL = processConnectionURL(
            initial: url,
            response: response.response.url
        )

        let newServerState = ServerState(
            urls: [connectionURL],
            currentURL: connectionURL,
            name: name,
            id: id,
            usersIDs: []
        )

        return newServerState
    }

    // In the event of redirects, get the new host URL from response
    private func processConnectionURL(initial url: URL, response: URL?) -> URL {

        guard let response else { return url }

        if url.scheme != response.scheme ||
            url.host != response.host
        {
            let newURL = response.absoluteString.trimmingSuffix(
                Paths.getPublicSystemInfo.url?.absoluteString ?? ""
            )
            return URL(string: newURL) ?? url
        }

        return url
    }

    private func isDuplicate(server: ServerState) -> Bool {
        let existingServer = try? SwiftfinStore
            .dataStack
            .fetchOne(From<ServerModel>().where(\.$id == server.id))
        return existingServer != nil
    }

    private func save(server: ServerState) async throws {

        let publicInfo = try await server.getPublicSystemInfo()

        try dataStack.perform { transaction in
            let newServer = transaction.create(Into<ServerModel>())

            newServer.urls = server.urls
            newServer.currentURL = server.currentURL
            newServer.name = server.name
            newServer.id = server.id
            newServer.users = []
        }

        StoredValues[.Server.publicInfo(id: server.id)] = publicInfo
    }

    // server has same id, but (possible) new URL
    private func addNewURL(server: ServerState) {
        do {
            let newState = try dataStack.perform { transaction in
                let existingServer = try self.dataStack.fetchOne(From<ServerModel>().where(\.$id == server.id))
                guard let editServer = transaction.edit(existingServer) else {
                    logger.critical("Could not find server to add new url")
                    throw JellyfinAPIError("An internal error has occurred")
                }

                editServer.urls.insert(server.currentURL)
                editServer.currentURL = server.currentURL

                return editServer.state
            }

            Notifications[.didChangeCurrentServerURL].post(newState)
        } catch {
            logger.critical("\(error.localizedDescription)")
        }
    }
}
