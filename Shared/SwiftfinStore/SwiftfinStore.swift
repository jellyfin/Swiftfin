//
// SwiftFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2021 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Foundation

enum SwiftfinStore {

	// MARK: State

	// Safe, copyable representations of their underlying CoreStoredObject's
	// Relationships are represented by the related object's IDs or value
	enum State {

		struct Server {
			let uri: String
			let name: String
			let id: String
			let os: String
			let version: String
			let userIDs: [String]

			fileprivate init(uri: String, name: String, id: String, os: String, version: String, usersIDs: [String]) {
				self.uri = uri
				self.name = name
				self.id = id
				self.os = os
				self.version = version
				self.userIDs = usersIDs
			}

			static var sample: Server {
				return Server(uri: "https://www.notaurl.com", name: "Johnny's Tree", id: "123abc", os: "macOS", version: "1.1.1",
				              usersIDs: ["1", "2"])
			}
		}

		struct User {
			let username: String
			let id: String
			let serverID: String
			let accessToken: String

			fileprivate init(username: String, id: String, serverID: String, accessToken: String) {
				self.username = username
				self.id = id
				self.serverID = serverID
				self.accessToken = accessToken
			}

			static var sample: User {
				return User(username: "JohnnyAppleseed", id: "123abc", serverID: "123abc", accessToken: "open-sesame")
			}
		}
	}

	// MARK: Models

	enum Models {

		final class StoredServer: CoreStoreObject {

			@Field.Stored("uri")
			var uri: String = ""

			@Field.Stored("name")
			var name: String = ""

			@Field.Stored("id")
			var id: String = ""

			@Field.Stored("os")
			var os: String = ""

			@Field.Stored("version")
			var version: String = ""

			@Field.Relationship("users", inverse: \StoredUser.$server)
			var users: Set<StoredUser>

			var state: State.Server {
				return State.Server(uri: uri,
				                    name: name,
				                    id: id,
				                    os: os,
				                    version: version,
				                    usersIDs: users.map { $0.id })
			}
		}

		final class StoredUser: CoreStoreObject {

			@Field.Stored("username")
			var username: String = ""

			@Field.Stored("id")
			var id: String = ""

			@Field.Stored("appleTVID")
			var appleTVID: String = ""

			@Field.Relationship("server")
			var server: StoredServer?

			@Field.Relationship("accessToken", inverse: \StoredAccessToken.$user)
			var accessToken: StoredAccessToken?

			var state: State.User {
				guard let server = server else { fatalError("No server associated with user") }
				guard let accessToken = accessToken else { fatalError("No access token associated with user") }
				return State.User(username: username,
				                  id: id,
				                  serverID: server.id,
				                  accessToken: accessToken.value)
			}
		}

		final class StoredAccessToken: CoreStoreObject {

			@Field.Stored("value")
			var value: String = ""

			@Field.Relationship("user")
			var user: StoredUser?
		}
	}

	// MARK: Errors

	enum Errors {
		case existingServer(State.Server)
		case existingUser(State.User)
	}

	// MARK: dataStack

	static let dataStack: DataStack = {
		let schema = CoreStoreSchema(modelVersion: "V1",
		                             entities: [
		                             	Entity<SwiftfinStore.Models.StoredServer>("Server"),
		                             	Entity<SwiftfinStore.Models.StoredUser>("User"),
		                             	Entity<SwiftfinStore.Models.StoredAccessToken>("AccessToken"),
		                             ],
		                             versionLock: [
		                             	"AccessToken": [
		                             		0xA8C4_75E8_7449_4BB1,
		                             		0x7948_6E93_449F_0B3D,
		                             		0xA7DC_4A00_0354_1EDB,
		                             		0x9418_3FAE_7580_EF72,
		                             	],
		                             	"Server": [
		                             		0x39C6_4A82_6739_077E,
		                             		0xA7AC_6374_4FD7_DF32,
		                             		0xEF3C_9D4F_E638_FBFB,
		                             		0xDABD_7962_56DF_14DB,
		                             	],
		                             	"User": [
		                             		0x845D_E08A_74BC_53ED,
		                             		0xE95A_406A_29F3_A5D0,
		                             		0x9EDA_7328_21A1_5EA9,
		                             		0xB5A_FA53_1E41_CE8A,
		                             	],
		                             ])

		let _dataStack = DataStack(schema)
		try! _dataStack.addStorageAndWait(SQLiteStore(fileName: "Swiftfin.sqlite",
		                                              localStorageOptions: .recreateStoreOnModelMismatch))
		return _dataStack
	}()
}

// MARK: LocalizedError

extension SwiftfinStore.Errors: LocalizedError {

	var title: String {
		switch self {
		case .existingServer:
			return "Existing Server"
		case .existingUser:
			return "Existing User"
		}
	}

	var errorDescription: String? {
		switch self {
		case let .existingServer(server):
			return "Server \(server.name) already exists with same server ID"
		case let .existingUser(user):
			return "User \(user.username) already exists with same user ID"
		}
	}
}
