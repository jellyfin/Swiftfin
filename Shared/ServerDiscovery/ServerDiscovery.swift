//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import UDPBroadcast

class ServerDiscovery {

    @Injected(\.logService)
    private var logger

    private var connection: UDPBroadcastConnection?

    init() {
        connection = try? UDPBroadcastConnection(
            port: 7359,
            handler: handleServerResponse,
            errorHandler: handleError
        )
    }

    var discoveredServers: AnyPublisher<ServerResponse, Never> {
        discoveredServersPublisher
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var discoveredServersPublisher = PassthroughSubject<ServerResponse, Never>()

    func broadcast() {
        try? connection?.sendBroadcast("Who is JellyfinServer?")
    }

    func close() {
        connection?.closeConnection()
        discoveredServersPublisher.send(completion: .finished)
    }

    private func handleServerResponse(_ ipAddress: String, _ port: Int, data: Data) {
        do {
            let response = try JSONDecoder().decode(ServerResponse.self, from: data)
            discoveredServersPublisher.send(response)

            logger.debug("Found local server: \"\(response.name)\" at: \(response.url.absoluteString)")
        } catch {
            logger.debug("Unable to decode local server response from: \(ipAddress):\(port)")
        }
    }

    private func handleError(_ error: UDPBroadcastConnection.ConnectionError) {
        logger.debug("Error handling response: \(error.localizedDescription)")
    }
}
