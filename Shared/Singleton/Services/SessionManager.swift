//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

//            }
//            .handleEvents(receiveOutput: { _, transaction in
//                try? transaction.commitAndWait()
//            })
//            .map { server, _ in
//                server.state
//            }
//            .eraseToAnyPublisher()
//    }
//
//    // MARK: setServerCurrentURI publisher
//
//    func setServerCurrentURI(server: SwiftfinStore.State.Server, uri: String) -> AnyPublisher<SwiftfinStore.State.Server, Error> {
//        Just(server)
//            .tryMap { server -> (SwiftfinStore.Models.StoredServer, UnsafeDataTransaction) in
//
//                let transaction = SwiftfinStore.dataStack.beginUnsafe()
//
//                guard let existingServer = try? SwiftfinStore.dataStack.fetchOne(
//                    From<SwiftfinStore.Models.StoredServer>(),
//                    [Where<SwiftfinStore.Models.StoredServer>(
//                        "id == %@",
//                        server.id
//                    )]
//                )
//                else {
//                    fatalError("No stored server associated with given state server?")
//                }
//
//                if !existingServer.uris.contains(uri) {
//                    fatalError("Attempting to set current uri while server doesn't contain it?")
//                }
//
//                guard let editServer = transaction.edit(existingServer) else { fatalError("Can't get proxy for existing object?") }
//                editServer.currentURI = uri
//
//                return (editServer, transaction)
//            }
//            .handleEvents(receiveOutput: { _, transaction in
//                try? transaction.commitAndWait()
//            })
//            .map { server, _ in
//                server.state
//            }
//            .eraseToAnyPublisher()
//    }
//
//    // MARK: signInUser publisher
//
//    // Logs in a user with an associated server, storing if successful
//    func signInUser(
//        server: SwiftfinStore.State.Server,
//        username: String,
//        password: String
//    ) -> AnyPublisher<SwiftfinStore.State.User, Error> {
//        JellyfinAPIAPI.basePath = server.currentURI
//
//        return UserAPI.authenticateUserByName(authenticateUserByNameRequest: .init(username: username, pw: password))
//            .processAuthenticationRequest(with: self, server: server)
//    }
//
//    // Logs in a user with an associated server, storing if successful
//    func signInUser(server: SwiftfinStore.State.Server, quickConnectSecret: String) -> AnyPublisher<SwiftfinStore.State.User, Error> {
//        JellyfinAPIAPI.basePath = server.currentURI
//
//        return UserAPI.authenticateWithQuickConnect(authenticateWithQuickConnectRequest: .init(secret: quickConnectSecret))
//            .processAuthenticationRequest(with: self, server: server)
//    }
//
//    // MARK: signInUser
//
//    func signInUser(server: SwiftfinStore.State.Server, user: SwiftfinStore.State.User) {
//        JellyfinAPIAPI.basePath = server.currentURI
//        Defaults[.lastServerUserID] = user.id
//        setAuthHeader(with: user.accessToken)
//        currentLogin = (server: server, user: user)
//        Notifications[.didSignIn].post()
//    }
//
//    // MARK: logout
//
//    func logout() {
//        currentLogin = nil
//        JellyfinAPIAPI.basePath = ""
//        setAuthHeader(with: "")
//        Defaults[.lastServerUserID] = nil
//        Notifications[.didSignOut].post()
//    }
//
//    // MARK: purge
//
//    func purge() {
//        // Delete all servers
//        let servers = fetchServers()
//
//        for server in servers {
//            delete(server: server)
//        }
//
//        Notifications[.didPurge].post()
//    }
//
//    // MARK: delete user
//
//    func delete(user: SwiftfinStore.State.User) {
//        guard let storedUser = try? SwiftfinStore.dataStack.fetchOne(
//            From<SwiftfinStore.Models.StoredUser>(),
//            [Where<SwiftfinStore.Models.StoredUser>("id == %@", user.id)]
//        )
//        else { fatalError("No stored user for state user?") }
//        _delete(user: storedUser, transaction: nil)
//    }
//
//    // MARK: delete server
//
//    func delete(server: SwiftfinStore.State.Server) {
//        guard let storedServer = try? SwiftfinStore.dataStack.fetchOne(
//            From<SwiftfinStore.Models.StoredServer>(),
//            [Where<SwiftfinStore.Models.StoredServer>("id == %@", server.id)]
//        )
//        else { fatalError("No stored server for state server?") }
//        _delete(server: storedServer, transaction: nil)
//    }
//
//    private func _delete(user: SwiftfinStore.Models.StoredUser, transaction: UnsafeDataTransaction?) {
////        guard let storedAccessToken = user.accessToken else { fatalError("No access token for stored user?") }
////
////        let transaction = transaction == nil ? SwiftfinStore.dataStack.beginUnsafe() : transaction!
////        transaction.delete(storedAccessToken)
////        transaction.delete(user)
////        try? transaction.commitAndWait()
//    }
//
//    private func _delete(server: SwiftfinStore.Models.StoredServer, transaction: UnsafeDataTransaction?) {
//        let transaction = transaction == nil ? SwiftfinStore.dataStack.beginUnsafe() : transaction!
//
//        for user in server.users {
//            _delete(user: user, transaction: transaction)
//        }
//
//        transaction.delete(server)
//        try? transaction.commitAndWait()
//    }
//
//    fileprivate func setAuthHeader(with accessToken: String) {
//        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
//        var deviceName = UIDevice.current.name
//        deviceName = deviceName.folding(options: .diacriticInsensitive, locale: .current)
//        deviceName = String(deviceName.unicodeScalars.filter { CharacterSet.urlQueryAllowed.contains($0) })
//
//        let platform: String
//        #if os(tvOS)
//        platform = "tvOS"
//        #else
//        platform = "iOS"
//        #endif
//
//        var header = "MediaBrowser "
//        header.append("Client=\"Jellyfin \(platform)\", ")
//        header.append("Device=\"\(deviceName)\", ")
//        header.append("DeviceId=\"\(platform)_\(UIDevice.vendorUUIDString)_\(String(Date().timeIntervalSince1970))\", ")
//        header.append("Version=\"\(appVersion ?? "0.0.1")\", ")
//        header.append("Token=\"\(accessToken)\"")
//
//        JellyfinAPIAPI.customHeaders["X-Emby-Authorization"] = header
//    }
// }
//
////extension AnyPublisher where Output == AuthenticationResult {
////    func processAuthenticationRequest(
////        with sessionManager: SessionManager,
////        server: SwiftfinStore.State.Server
////    ) -> AnyPublisher<SwiftfinStore.State.User, Error> {
////        Just(.sample)
////            .eraseToAnyPublisher()
////
////
////        self
////            .tryMap { response -> (SwiftfinStore.Models.StoredServer, SwiftfinStore.Models.StoredUser, UnsafeDataTransaction) in
////
////                guard let accessToken = response.accessToken else { throw JellyfinAPIError("Access token missing from network call") }
////
////                let transaction = SwiftfinStore.dataStack.beginUnsafe()
////                let newUser = transaction.create(Into<SwiftfinStore.Models.StoredUser>())
////

////
////                newUser.username = username
////                newUser.id = id
////                newUser.appleTVID = ""
////
////                // Check for existing user on device

////
////                let newAccessToken = transaction.create(Into<SwiftfinStore.Models.StoredAccessToken>())
////                newAccessToken.value = accessToken
////                newUser.accessToken = newAccessToken
////

////
////                guard let editUserServer = transaction.edit(userServer) else { fatalError("Can't get proxy for existing object?") }
////                editUserServer.users.insert(newUser)
////
////                return (editUserServer, newUser, transaction)
////            }
////            .handleEvents(receiveOutput: { server, user, transaction in
////                sessionManager.setAuthHeader(with: user.accessToken?.value ?? "")
////                try? transaction.commitAndWait()
////
////                // Fetch for the right queue
////                let currentServer = SwiftfinStore.dataStack.fetchExisting(server)!
////                let currentUser = SwiftfinStore.dataStack.fetchExisting(user)!
////
////                Defaults[.lastServerUserID] = user.id
////
////                sessionManager.currentLogin = (server: currentServer.state, user: currentUser.state)
////                Notifications[.didSignIn].post()
////            })
////            .map { _, user, _ in
////                user.state
////            }
////            .eraseToAnyPublisher()
////    }
////}
