//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Foundation
import JellyfinAPI
import Pulse
import UIKit

typealias ServerModel = SwiftfinStore.V2.StoredServer
typealias UserModel = SwiftfinStore.V2.StoredUser

typealias ServerState = SwiftfinStore.State.Server
typealias UserState = SwiftfinStore.State.User

// MARK: Versions

enum SwiftfinStore {
    enum V1 {}
    enum V2 {}
}

extension SwiftfinStore {

    // MARK: State

    // Static representations of model objects
    // Relationships are represented by object IDs
    enum State {

        struct Server: Hashable, Identifiable {
            let urls: Set<URL>
            let currentURL: URL
            let name: String
            let id: String
            let userIDs: [String]

            init(
                urls: Set<URL>,
                currentURL: URL,
                name: String,
                id: String,
                usersIDs: [String]
            ) {
                self.urls = urls
                self.currentURL = currentURL
                self.name = name
                self.id = id
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
                    usersIDs: ["1", "2"]
                )
            }

            var client: JellyfinClient {
                JellyfinClient(
                    configuration: .swiftfinConfiguration(url: currentURL),
                    sessionDelegate: URLSessionProxyDelegate(logger: LogManager.pulseNetworkLogger())
                )
            }
        }

        struct User: Hashable, Identifiable {

            let accessToken: String
            let id: String
            let serverID: String
            let username: String
            let image: UIImage?

            init(
                accessToken: String,
                id: String,
                serverID: String,
                username: String,
                image: UIImage?
            ) {
                self.accessToken = accessToken
                self.id = id
                self.serverID = serverID
                self.username = username
                self.image = image
            }

            static var sample: Self {
                .init(
                    accessToken: "open-sesame",
                    id: "123abc",
                    serverID: "123abc",
                    username: "JohnnyAppleseed",
                    image: nil
                )
            }
        }
    }

    // MARK: dataStack

    static let dataStack: DataStack = {

        let _dataStack = DataStack(
            //            V1.schema,
            V2.schema
//            migrationChain: ["V1", "V2"]
        )

//        DispatchQueue.main.async {
//            _ = _dataStack.addStorage(SQLiteStore(fileName: "Swiftfin.sqlite", localStorageOptions: .recreateStoreOnModelMismatch)) {
//                result in
//                print(result)
//            }
//        }

        try! _dataStack.addStorageAndWait(SQLiteStore(
            fileName: "Swiftfin.sqlite",
            localStorageOptions: .recreateStoreOnModelMismatch
        ))

        return _dataStack
    }()
}
