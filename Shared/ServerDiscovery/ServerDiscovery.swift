//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import UDPBroadcast

class ServerDiscovery {

    @Injected(LogManager.service)
    private var logger

    struct ServerLookupResponse: Codable, Hashable, Identifiable {

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        private let address: String
        let id: String
        let name: String

        var url: URL {
            URL(string: self.address)!
        }

        var host: String {
            let components = URLComponents(string: self.address)
            if let host = components?.host {
                return host
            }
            return self.address
        }

        var port: Int {
            let components = URLComponents(string: self.address)
            if let port = components?.port {
                return port
            }
            return 7359
        }

        enum CodingKeys: String, CodingKey {
            case address = "Address"
            case id = "Id"
            case name = "Name"
        }
    }

    private var connection: UDPBroadcastConnection?

    init() {}

    func locateServer(completion: @escaping (ServerLookupResponse?) -> Void) {

        func receiveHandler(_ ipAddress: String, _ port: Int, _ data: Data) {
            do {
                let response = try JSONDecoder().decode(ServerLookupResponse.self, from: data)
                logger.debug("Received JellyfinServer from \"\(response.name)\"")
                completion(response)
            } catch {
                completion(nil)
            }
        }

        func errorHandler(error: UDPBroadcastConnection.ConnectionError) {
            logger.error("Error handling response: \(error.localizedDescription)")
        }

        do {
            self.connection = try! UDPBroadcastConnection(port: 7359, handler: receiveHandler, errorHandler: errorHandler)
            try self.connection?.sendBroadcast("Who is JellyfinServer?")
            logger.debug("Discovery broadcast sent")
        } catch {
            logger.error("Error sending discovery broadcast")
        }
    }
}
