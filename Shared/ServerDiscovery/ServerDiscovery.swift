//
// SwiftFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2021 Jellyfin & Jellyfin Contributors
//

import Foundation

public class ServerDiscovery {
	public struct ServerLookupResponse: Codable, Hashable, Identifiable {

		public func hash(into hasher: inout Hasher) {
			hasher.combine(id)
		}

		private let address: String
		public let id: String
		public let name: String

		public var url: URL {
			URL(string: address)!
		}

		public var host: String {
			let components = URLComponents(string: address)
			if let host = components?.host {
				return host
			}
			return address
		}

		public var port: Int {
			let components = URLComponents(string: address)
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
		func receiveHandler(_ ipAddress: String, _ port: Int, _ response: Data) {}

		func errorHandler(error: UDPBroadcastConnection.ConnectionError) {}
		self.broadcastConn = try! UDPBroadcastConnection(port: 7359, handler: receiveHandler, errorHandler: errorHandler)
	}

	public func locateServer(completion: @escaping (ServerLookupResponse?) -> Void) {
		func receiveHandler(_ ipAddress: String, _ port: Int, _ data: Data) {
			do {
				let response = try JSONDecoder().decode(ServerLookupResponse.self, from: data)
				LogManager.shared.log.debug("Received JellyfinServer from \"\(response.name)\"", tag: "ServerDiscovery")
				completion(response)
			} catch {
				completion(nil)
			}
		}
		broadcastConn.handler = receiveHandler
		do {
			try broadcastConn.sendBroadcast("Who is JellyfinServer?")
			LogManager.shared.log.debug("Discovery broadcast sent", tag: "ServerDiscovery")
		} catch {
			print(error)
		}
	}
}
