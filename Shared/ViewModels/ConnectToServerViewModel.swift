//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Foundation
import Get
import JellyfinAPI
import OrderedCollections
import Pulse

// Note: Discovered servers works by always listening on a port for
//       server responses and will send broadcasts as requested.
//       This won't "clear" servers that no longer send a response,
//       but case is negligible and just requires re-opening.

final class ConnectToServerViewModel: ViewModel, Eventful, Stateful {

    // MARK: Event

    enum Event {
        case connected(ServerState)
        case duplicateServer(ServerState)
        case error(JellyfinAPIError)
    }

    // MARK: Action

    enum Action: Equatable {
        case searchForServers
        case connect(String)
        case cancel
        case addNewURL(ServerState)
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
    @Published
    var discoveredServers: OrderedSet<ServerState> = []
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
                    let _ = self.discoveredServers.append(response.asServerState)
                }
            }
        }
        .store(in: &cancellables)
    }

    func respond(to action: Action) -> State {
        switch action {
        case .searchForServers:
            Task {
                await MainActor.run {
                    let _ = backgroundStates.append(.searching)
                }

                await searchForServers()

                await MainActor.run {
                    let _ = backgroundStates.remove(.searching)
                }
            }
            .store(in: &cancellables)

            return state
        case let .connect(url):
            connectTask?.cancel()

            connectTask = Task {
                do {
                    let server = try await connectToServer(url: url)

                    if isDuplicate(server: server) {
                        await MainActor.run {
                            self.eventSubject.send(.duplicateServer(server))
                        }
                    } else {
                        try save(server: server)

                        await MainActor.run {
                            self.eventSubject.send(.connected(server))
                        }
                    }

                    await MainActor.run {
                        self.state = .initial
                    }
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                        self.state = .initial
                    }
                }
            }
            .asAnyCancellable()

            return .connecting
        case .cancel:
            connectTask?.cancel()

            return .initial
        case let .addNewURL(serverState):
            return state
        }
    }

    private func connectToServer(url: String) async throws -> ServerState {

        let formattedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)
            .prepending("http://", if: !url.contains("://"))

        guard let url = URL(string: formattedURL) else { throw JellyfinAPIError("Invalid URL") }

        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: url),
            sessionDelegate: URLSessionProxyDelegate()
        )

        let response = try await client.send(Paths.getPublicSystemInfo)

        guard let name = response.value.serverName,
              let id = response.value.id
        else {
            throw JellyfinAPIError("Missing server data from network call")
        }

        // in case of redirects, we must process the new URL

        let connectionURL = processConnectionURL(initial: url, response: response.response.url)

        let newServerState = ServerState(
            urls: [connectionURL],
            currentURL: connectionURL,
            name: name,
            id: id,
            usersIDs: []
        )

        return newServerState
    }

    // TODO: this probably isn't the best way to properly handle this, fix if necessary
    private func processConnectionURL(initial url: URL, response: URL?) -> URL {

        guard let response else { return url }

        if url.scheme != response.scheme ||
            url.host != response.host
        {
            var newURL = response.absoluteString.trimmingSuffix(Paths.getPublicSystemInfo.url?.absoluteString ?? "")

            // if ended in a "/"
            if url.absoluteString.last == "/" {
                newURL.append("/")
            }

            return URL(string: newURL) ?? url
        }

        return url
    }

    private func isDuplicate(server: ServerState) -> Bool {
        if let _ = try? dataStack.fetchOne(
            From<ServerModel>(),
            [Where<ServerModel>(
                "id == %@",
                server.id
            )]
        ) {
            return true
        }
        return false
    }

    private func save(server: ServerState) throws {
        try dataStack.perform { transaction in
            let newServer = transaction.create(Into<ServerModel>())

            newServer.urls = server.urls
            newServer.currentURL = server.currentURL
            newServer.name = server.name
            newServer.id = server.id
            newServer.users = []
        }
    }

    private func add(url: URL, to server: ServerState) throws {
        try dataStack.perform { transaction in
            let existingServer = try! dataStack.fetchOne(
                From<ServerModel>(),
                [Where<ServerModel>(
                    "id == %@",
                    server.id
                )]
            )

            let editServer = transaction.edit(existingServer)!
            editServer.urls.insert(url)
        }
    }

    private func searchForServers() async {
        discovery.broadcast()

        // give illusion of "discovering" even
        // though we're always listening

        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}
