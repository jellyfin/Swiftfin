//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Foundation

enum SwiftfinStore {

    // MARK: State

    // Safe, copyable representations of their underlying CoreStoredObject
    // Relationships are represented by the related object's IDs or value
    enum State {

        struct Server: Hashable, Identifiable {
            let uris: Set<String>
            let currentURI: String
            let name: String
            let id: String
            let os: String
            let version: String
            let userIDs: [String]

            init(
                uris: Set<String>,
                currentURI: String,
                name: String,
                id: String,
                os: String,
                version: String,
                usersIDs: [String]
            ) {
                self.uris = uris
                self.currentURI = currentURI
                self.name = name
                self.id = id
                self.os = os
                self.version = version
                self.userIDs = usersIDs
            }

            static var sample: Server {
                Server(
                    uris: ["https://www.notaurl.com", "http://www.maybeaurl.org"],
                    currentURI: "https://www.notaurl.com",
                    name: "Johnny's Tree",
                    id: "123abc",
                    os: "macOS",
                    version: "1.1.1",
                    usersIDs: ["1", "2"]
                )
            }
        }

        struct User: Hashable, Identifiable {
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
                User(
                    username: "JohnnyAppleseed",
                    id: "123abc",
                    serverID: "123abc",
                    accessToken: "open-sesame"
                )
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
                State.Server(
                    uris: uris,
                    currentURI: currentURI,
                    name: name,
                    id: id,
                    os: os,
                    version: version,
                    usersIDs: users.map(\.id)
                )
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
                return State.User(
                    username: username,
                    id: id,
                    serverID: server.id,
                    accessToken: accessToken.value
                )
            }
        }

        final class StoredAccessToken: CoreStoreObject {

            @Field.Stored("value")
            var value: String = ""

            @Field.Relationship("user")
            var user: StoredUser?
        }
    }

    // MARK: Error

    enum Error {
        case existingServer(State.Server)
        case existingUser(State.User)
    }

    // MARK: dataStack

    static let dataStack: DataStack = {
        let schema = CoreStoreSchema(
            modelVersion: "V1",
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
                    0x936B_46AC_D8E8_F0E3,
                    0x5989_0D4D_9F3F_885F,
                    0x819C_F7A4_ABF9_8B22,
                    0xE161_25C5_AF88_5A06,
                ],
                "User": [
                    0x845D_E08A_74BC_53ED,
                    0xE95A_406A_29F3_A5D0,
                    0x9EDA_7328_21A1_5EA9,
                    0xB5A_FA53_1E41_CE8A,
                ],
            ]
        )

        let _dataStack = DataStack(schema)
        try! _dataStack.addStorageAndWait(SQLiteStore(
            fileName: "Swiftfin.sqlite",
            localStorageOptions: .recreateStoreOnModelMismatch
        ))
        return _dataStack
    }()
}

// MARK: LocalizedError

extension SwiftfinStore.Error: LocalizedError {

    var title: String {
        switch self {
        case .existingServer:
            return L10n.existingServer
        case .existingUser:
            return L10n.existingUser
        }
    }

    var errorDescription: String? {
        switch self {
        case let .existingServer(server):
            return L10n.serverAlreadyConnected(server.name)
        case let .existingUser(user):
            return L10n.userAlreadySignedIn(user.username)
        }
    }
}
