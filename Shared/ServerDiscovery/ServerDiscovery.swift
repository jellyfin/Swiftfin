//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import UDPBroadcast

public class ServerDiscovery {

    @Injected(LogManager.service)
    private var logger

    public struct ServerLookupResponse: Codable, Hashable, Identifiable {

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        private let address: String
        public let id: String
        public let name: String

        public var url: URL {
            URL(string: self.address)!
        }

        public var host: String {
            let components = URLComponents(string: self.address)
            if let host = components?.host {
                return host
            }
            return self.address
        }

        public var port: Int {
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

    public func locateServer(completion: @escaping (ServerLookupResponse?) -> Void) {

        func receiveHandler(_ ipAddress: String, _ port: Int, _ data: Data) {
            do {
                let response = try JSONDecoder().decode(ServerLookupResponse.self, from: data)
                logger.debug("Received JellyfinServer from \"\(response.name)\"", tag: "ServerDiscovery")
                completion(response)
            } catch {
                completion(nil)
            }
        }

        func errorHandler(error: UDPBroadcastConnection.ConnectionError) {
            logger.error("Error handling response: \(error.localizedDescription)", tag: "ServerDiscovery")
        }

        do {
            self.connection = try! UDPBroadcastConnection(port: 7359, handler: receiveHandler, errorHandler: errorHandler)
            try self.connection?.sendBroadcast("Who is JellyfinServer?")
            logger.debug("Discovery broadcast sent", tag: "ServerDiscovery")
        } catch {
            logger.error("Error sending discovery broadcast", tag: "ServerDiscovery")
        }
    }
}
