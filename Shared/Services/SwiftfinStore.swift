//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Foundation

typealias ServerModel = SwiftfinStore.Models.StoredServer
typealias UserModel = SwiftfinStore.Models.StoredUser

typealias ServerState = SwiftfinStore.State.Server
typealias UserState = SwiftfinStore.State.User

enum SwiftfinStore {

    // MARK: State

    // Safe, copyable representations of their underlying CoreStoredObject
    // Relationships are represented by object IDs
    enum State {

        struct Server: Hashable, Identifiable {
            let urls: Set<URL>
            let currentURL: URL
            let name: String
            let id: String
            let os: String
            let version: String
            let userIDs: [String]

            init(
                urls: Set<URL>,
                currentURL: URL,
                name: String,
                id: String,
                os: String,
                version: String,
                usersIDs: [String]
            ) {
                self.urls = urls
                self.currentURL = currentURL
                self.name = name
                self.id = id
                self.os = os
                self.version = version
                self.userIDs = usersIDs
            }

            static var sample: Server {
                .init(
                    urls: [
                        .init(string: "http://localhost:8096")!,
                    ],
                    currentURL: .init(string: "http://localhost:8096")!,
                    name: "Johnny's Tree",
                    id: "123abc",
                    os: "macOS",
                    version: "1.1.1",
                    usersIDs: ["1", "2"]
                )
            }
        }

        struct User: Hashable, Identifiable {

            let accessToken: String
            let id: String
            let serverID: String
            let username: String

            fileprivate init(
                accessToken: String,
                id: String,
                serverID: String,
                username: String
            ) {
                self.accessToken = accessToken
                self.id = id
                self.serverID = serverID
                self.username = username
            }

            static var sample: Self {
                .init(
                    accessToken: "open-sesame",
                    id: "123abc",
                    serverID: "123abc",
                    username: "JohnnyAppleseed"
                )
            }
        }
    }

    // MARK: Models

    enum Models {

        final class StoredServer: CoreStoreObject {

            @Field.Coded("urls", coder: FieldCoders.Json.self)
            var urls: Set<URL> = []

            @Field.Stored("currentURL")
            var currentURL: URL = .init(string: "/")!

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

            var state: ServerState {
                .init(
                    urls: urls,
                    currentURL: currentURL,
                    name: name,
                    id: id,
                    os: os,
                    version: version,
                    usersIDs: users.map(\.id)
                )
            }
        }

        final class StoredUser: CoreStoreObject {

            @Field.Stored("accessToken")
            var accessToken: String = ""

            @Field.Stored("username")
            var username: String = ""

            @Field.Stored("id")
            var id: String = ""

            @Field.Stored("appleTVID")
            var appleTVID: String = ""

            @Field.Relationship("server")
            var server: StoredServer?

            var state: UserState {
                guard let server = server else { fatalError("No server associated with user") }
                return .init(
                    accessToken: accessToken,
                    id: id,
                    serverID: server.id,
                    username: username
                )
            }
        }
    }

    // MARK: Error

    enum Error {
        case existingServer(State.Server)
        case existingUser(State.User)
    }

    // MARK: dataStack

    private static let v1Schema = CoreStoreSchema(
        modelVersion: "V1",
        entities: [
            Entity<SwiftfinStore.Models.StoredServer>("Server"),
            Entity<SwiftfinStore.Models.StoredUser>("User"),
        ],
        versionLock: [
            "Server": [
                0x4E8_8201_635C_2BB5,
                0x7A7_85D8_A65D_177C,
                0x3FE6_7B5B_D402_6EEE,
                0x8893_16D4_188E_B136,
            ],
            "User": [
                0x1001_44F1_4D4D_5A31,
                0x828F_7943_7D0B_4C03,
                0x3824_5761_B815_D61A,
                0x3C1D_BF68_E42B_1DA6,
            ],
        ]
    )

    static let dataStack: DataStack = {
        let _dataStack = DataStack(v1Schema)
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
