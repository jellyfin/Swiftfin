//
 /*
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import CoreStore
import Defaults

enum SwiftfinStore {

    // MARK: State
    // Safe, copyable representations of their underlying CoreStoredObject
    // Relationships are represented by the related object's IDs or value
    enum State {

        struct Server {
            let uris: Set<String>
            let currentURI: String
            let name: String
            let id: String
            let os: String
            let version: String
            let userIDs: [String]

            fileprivate init(uris: Set<String>, currentURI: String, name: String, id: String, os: String, version: String, usersIDs: [String]) {
                self.uris = uris
                self.currentURI = currentURI
                self.name = name
                self.id = id
                self.os = os
                self.version = version
                self.userIDs = usersIDs
            }

            static var sample: Server {
                return Server(uris: ["https://www.notaurl.com", "http://www.maybeaurl.org"],
                              currentURI: "https://www.notaurl.com",
                              name: "Johnny's Tree",
                              id: "123abc",
                              os: "macOS",
                              version: "1.1.1",
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
                return User(username: "JohnnyAppleseed",
                            id: "123abc",
                            serverID: "123abc",
                            accessToken: "open-sesame")
            }
        }
    }

    // MARK: Models
    enum Models {

        final class StoredServer: CoreStoreObject {

            @Field.Coded("uris", coder: FieldCoders.Json.self)
            var uris: Set<String> = []

            @Field.Stored("currentURI")
            var currentURI: String = ""

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
                return State.Server(uris: uris,
                                    currentURI: currentURI,
                                    name: name,
                                    id: id,
                                    os: os,
                                    version: version,
                                    usersIDs: users.map({ $0.id }))
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
                                        Entity<SwiftfinStore.Models.StoredAccessToken>("AccessToken")
                                     ],
                                     versionLock: [
                                         "AccessToken": [0xa8c475e874494bb1, 0x79486e93449f0b3d, 0xa7dc4a0003541edb, 0x94183fae7580ef72],
                                         "Server": [0x936b46acd8e8f0e3, 0x59890d4d9f3f885f, 0x819cf7a4abf98b22, 0xe16125c5af885a06],
                                         "User": [0x845de08a74bc53ed, 0xe95a406a29f3a5d0, 0x9eda732821a15ea9, 0xb5afa531e41ce8a]
                                     ])

        let _dataStack = DataStack(schema)
        try! _dataStack.addStorageAndWait(
            SQLiteStore(
                fileName: "Swiftfin.sqlite",
                localStorageOptions: .recreateStoreOnModelMismatch
            )
        )
        return _dataStack
    }()
}

// MARK: LocalizedError
extension SwiftfinStore.Errors: LocalizedError {

    var title: String {
        switch self {
        case .existingServer(_):
            return "Existing Server"
        case .existingUser(_):
            return "Existing User"
        }
    }

    var errorDescription: String? {
        switch self {
        case .existingServer(let server):
            return "Server \(server.name) already exists with same server ID"
        case .existingUser(let user):
            return "User \(user.username) already exists with same user ID"
        }
    }
}
