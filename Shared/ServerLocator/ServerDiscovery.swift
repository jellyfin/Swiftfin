//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Created by Noah Kamara
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation

public class ServerDiscovery {
    public struct ServerCredential: Codable {
        public let host: String
        public let port: Int
        public let username: String
        public let password: String
        public let deviceId: String

        public init(_ host: String, _ port: Int, _ username: String, _ password: String, _ deviceId: String = UUID().uuidString) {
            self.host = host
            self.port = port
            self.username = username
            self.password = password
            self.deviceId = deviceId
        }
    }

    public struct ServerLookupResponse: Codable, Hashable, Identifiable {

        public func hash(into hasher: inout Hasher) {
            return hasher.combine(id)
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
            return 8096
        }

        enum CodingKeys: String, CodingKey {
            case address = "Address"
            case id = "Id"
            case name = "Name"
        }
    }
    private let broadcastConn: UDPBroadcastConnection

    public init() {
        func receiveHandler(_ ipAddress: String, _ port: Int, _ response: Data) {
        }

        func errorHandler(error: UDPBroadcastConnection.ConnectionError) {
        }
        self.broadcastConn = try! UDPBroadcastConnection(port: 7359, handler: receiveHandler, errorHandler: errorHandler)
    }

    public func locateServer(completion: @escaping (ServerLookupResponse?) -> Void) {
        func receiveHandler(_ ipAddress: String, _ port: Int, _ data: Data) {
            do {
                let response = try JSONDecoder().decode(ServerLookupResponse.self, from: data)
                completion(response)
            } catch {
                completion(nil)
            }
        }
        self.broadcastConn.handler = receiveHandler
        do {
            try broadcastConn.sendBroadcast("Who is JellyfinServer?")
        } catch {
            print(error)
        }
    }
}
