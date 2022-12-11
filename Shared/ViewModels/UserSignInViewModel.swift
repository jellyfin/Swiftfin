//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation
import Pulse
import JellyfinAPI

final class UserSignInViewModel: ViewModel {

    @Published
    var publicUsers: [UserDto] = []
    @Published
    var quickConnectCode: String?
    @Published
    var quickConnectEnabled = false
    
    let client: JellyfinClient
    private var quickConnectWorkItem: DispatchWorkItem?
    let server: SwiftfinStore.State.Server
    private var quickConnectTimer: RepeatingTimer?
    private var quickConnectSecret: String?

    init(server: ServerState) {
        self.client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: server.currentURL),
            sessionDelegate: URLSessionProxyDelegate()
        )
        self.server = server
        super.init()
    }

    func signIn(username: String, password: String) async throws {

        let username = username.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)
        
        let response = try await client.signIn(username: username, password: password)
        
        guard let accessToken = response.accessToken,
              let username = response.user?.name,
              let id = response.user?.id else { throw JellyfinAPIError("Missing user data from network call") }
        
        if let existingUser = try? SwiftfinStore.dataStack.fetchOne(
            From<UserModel>(),
            [Where<UserModel>(
                "id == %@",
                id
            )]
        ) {
            throw SwiftfinStore.Error.existingUser(existingUser.state)
        }
        
        guard let storedServer = try? SwiftfinStore.dataStack.fetchOne(
            From<SwiftfinStore.Models.StoredServer>(),
            [
                Where<SwiftfinStore.Models.StoredServer>(
                    "id == %@",
                    server.id
                ),
            ]
        )
        else { fatalError("No stored server associated with given state server?") }
        
        try SwiftfinStore.dataStack.perform { transaction in
            let newUser = transaction.create(Into<UserModel>())
            
            newUser.accessToken = accessToken
            newUser.appleTVID = ""
            newUser.id = id
            newUser.username = username
            
            let editServer = transaction.edit(storedServer)!
            
            editServer.users.insert(newUser)
        }
    }

    func getPublicUsers() async throws {
        let publicUsersPath = Paths.getPublicUsers
        let response = try await client.send(publicUsersPath)
        
        await MainActor.run {
            publicUsers = response.value
        }
    }

    func checkQuickConnect() async throws {
        let quickConnectEnabledPath = Paths.getEnabled
        let response = try await client.send(quickConnectEnabledPath)
        let decoder = JSONDecoder()
        let isEnabled = try? decoder.decode(Bool.self, from: response.value)
        
        await MainActor.run {
            quickConnectEnabled = isEnabled ?? false
        }
    }

    func startQuickConnect(_ onSuccess: @escaping () -> Void) async throws -> AsyncStream<Void> {
        let initiatePath = Paths.initiate
        let response = try await client.send(initiatePath)
        
        await MainActor.run {
            quickConnectSecret = response.value.secret
            quickConnectCode = response.value.code
        }
        
        return .init { continuation in
            
        }
        
        
//        QuickConnectAPI.initiate()
//            .sink(receiveCompletion: { completion in
//                self.handleAPIRequestError(completion: completion)
//            }, receiveValue: { response in
//
//                self.quickConnectSecret = response.secret
//                self.quickConnectCode = response.code
//                self.logger.debug("QuickConnect code: \(response.code ?? .emptyDash)")
//
//                self.quickConnectTimer = RepeatingTimer(interval: 5) {
//                    self.checkAuthStatus(onSuccess)
//                }
//
//                self.quickConnectTimer?.start()
//            })
//            .store(in: &cancellables)
    }

    private func checkAuthStatus(stream: AsyncStream<QuickConnectResult>) async throws {
        guard let quickConnectSecret else { return }
        let connectPath = Paths.connect(secret: quickConnectSecret)
        let response = try await client.send(connectPath)
        
        if response.value.isAuthenticated ?? false {
            
        }
        
        
//        guard let quickConnectSecret = quickConnectSecret else { return }

//        QuickConnectAPI.connect(secret: quickConnectSecret)
//            .sink(receiveCompletion: { _ in
//                // Prefer not to handle error handling like normal as
//                // this is a repeated call
//            }, receiveValue: { value in
//                guard let authenticated = value.authenticated, authenticated else {
//                    self.logger.debug("QuickConnect not authenticated yet")
//                    return
//                }
//
//                self.stopQuickConnectAuthCheck()
//                onSuccess()
//
////                SessionManager.main.signInUser(server: self.server, quickConnectSecret: quickConnectSecret)
////                    .trackActivity(self.loading)
////                    .sink { completion in
////                        self.handleAPIRequestError(displayMessage: L10n.unableToConnectServer, completion: completion)
////                    } receiveValue: { _ in
////                    }
////                    .store(in: &self.cancellables)
//            })
//            .store(in: &cancellables)
    }

    func stopQuickConnectAuthCheck() {
//        DispatchQueue.main.async {
//            self.quickConnectTimer?.stop()
//            self.quickConnectTimer = nil
//        }
    }
}
