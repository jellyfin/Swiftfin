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

@MainActor
@Stateful
final class ConnectToServerViewModel: ViewModel {

    @CasePathable
    enum Action {
        case addNewURL(serverState: ServerState)
        case cancel
        case connect(url: String)
        case searchForServers

        var transition: Transition {
            switch self {
            case .addNewURL, .searchForServers: .none
            case .cancel: .to(.initial)
            case .connect: .loop(.connecting)
            }
        }
    }

    enum Event {
        case connected(ServerState)
        case duplicateServer(ServerState)
        case error
    }

    enum State {
        case connecting
        case initial
    }

    // no longer-found servers are not cleared, but not an issue
    @Published
    var localServers: OrderedSet<ServerState> = []

    private let discovery = ServerDiscovery()

    deinit {
        discovery.close()
    }

    override init() {
        super.init()

        // TODO: refactor, causing retain cycle
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

    @Function(\Action.Cases.connect)
    private func connectToServer(_ url: String) async throws {

        let formattedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)
            .trimmingCharacters(in: ["/"])
            .prepending("http://", if: !url.contains("://"))

        guard let url = URL(string: formattedURL) else { throw ErrorMessage("Invalid URL") }

        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: url),
            sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin())
        )

        let response = try await client.send(Paths.getPublicSystemInfo)

        guard let name = response.value.serverName,
              let id = response.value.id
        else {
            logger.critical("Missing server data from network call")
            throw ErrorMessage(L10n.unknownError)
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

        if isDuplicate(server: newServerState) {
            // server has same id, but (possible) new URL
            events.send(.duplicateServer(newServerState))
        } else {
            try await save(server: newServerState)
            events.send(.connected(newServerState))
        }
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
    @Function(\Action.Cases.addNewURL)
    private func _addNewURL(_ server: ServerState) throws {
        let newState = try dataStack.perform { transaction in
            let existingServer = try self.dataStack.fetchOne(From<ServerModel>().where(\.$id == server.id))
            guard let editServer = transaction.edit(existingServer) else {
                logger.critical("Could not find server to add new url")
                throw ErrorMessage("An internal error has occurred")
            }

            editServer.urls.insert(server.currentURL)
            editServer.currentURL = server.currentURL

            return editServer.state
        }

        Notifications[.didChangeCurrentServerURL].post(newState)
    }

    @Function(\Action.Cases.searchForServers)
    private func _searchForServers() {
        discovery.broadcast()
    }
}
