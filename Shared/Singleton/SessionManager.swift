//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import CoreData
import CoreStore
import Defaults
import Foundation
import JellyfinAPI
import KeychainSwift
import UIKit

#if os(tvOS)
import TVServices
import SwiftUIFocusGuide
#endif

typealias CurrentLogin = (server: SwiftfinStore.State.Server, user: SwiftfinStore.State.User)

// MARK: NewSessionManager
final class SessionManager {
    
    // MARK: currentLogin
    private(set) var currentLogin: CurrentLogin!
    
    // MARK: main
    static let main = SessionManager()
    
    private init() {
        if let lastUserID = SwiftfinStore.Defaults.suite[.lastServerUserID],
           let user = try? SwiftfinStore.dataStack.fetchOne(From<SwiftfinStore.Models.StoredUser>(),
                                                            [Where<SwiftfinStore.Models.StoredUser>("id == %@", lastUserID)]) {
            
            guard let server = user.server, let accessToken = user.accessToken else { fatalError("No associated server or access token for last user?") }
            guard let existingServer = SwiftfinStore.dataStack.fetchExisting(server) else { return }
            
            JellyfinAPI.basePath = server.uri
            setAuthHeader(with: accessToken.value)
            currentLogin = (server: existingServer.state, user: user.state)
        }
    }
    
    private func generateServerUserID(server: SwiftfinStore.Models.StoredServer, user: SwiftfinStore.Models.StoredUser) -> String {
        return "\(server.id)-\(user.id)"
    }
    
    func fetchServers() -> [SwiftfinStore.State.Server] {
        let servers = try! SwiftfinStore.dataStack.fetchAll(From<SwiftfinStore.Models.StoredServer>())
        return servers.map({ $0.state })
    }
    
    func fetchUsers(for server: SwiftfinStore.State.Server) -> [SwiftfinStore.State.User] {
        guard let storedServer = try? SwiftfinStore.dataStack.fetchOne(From<SwiftfinStore.Models.StoredServer>(),
                                                                 Where<SwiftfinStore.Models.StoredServer>("id == %@", server.id))
            else { fatalError("No stored server associated with given state server?") }
        return storedServer.users.map({ $0.state }).sorted(by: { $0.username < $1.username })
    }
    
    // Connects to a server at the given uri, storing if successful
    func connectToServer(with uri: String) -> AnyPublisher<SwiftfinStore.State.Server, Error> {
        var uri = uri
        if !uri.contains("http") {
            uri = "https://" + uri
        }
        if uri.last == "/" {
            uri = String(uri.dropLast())
        }
        
        JellyfinAPI.basePath = uri
        
        return SystemAPI.getPublicSystemInfo()
            .map({ response -> (SwiftfinStore.Models.StoredServer, UnsafeDataTransaction) in
                let transaction = SwiftfinStore.dataStack.beginUnsafe()
                let newServer = transaction.create(Into<SwiftfinStore.Models.StoredServer>())
                newServer.uri = response.localAddress ?? "SfUri"
                newServer.name = response.serverName ?? "SfServerName"
                newServer.id = response.id ?? ""
                newServer.os = response.operatingSystem ?? "SfOS"
                newServer.version = response.version ?? "SfVersion"
                newServer.users = []
                
                return (newServer, transaction)
            })
            .handleEvents(receiveOutput: { (_, transaction) in
                try? transaction.commitAndWait()
            })
            .map({ (server, _) in
                return server.state
            })
            .eraseToAnyPublisher()
    }
    
    // Logs in a user with an associated server, storing if successful
    func loginUser(server: SwiftfinStore.State.Server, username: String, password: String) -> AnyPublisher<SwiftfinStore.State.User, Error> {
        setAuthHeader(with: "")
        
        return UserAPI.authenticateUserByName(authenticateUserByName: AuthenticateUserByName(username: username, pw: password))
            .map({ response -> (SwiftfinStore.Models.StoredServer, SwiftfinStore.Models.StoredUser, UnsafeDataTransaction) in
                
                guard let accessToken = response.accessToken else { fatalError("Received successful user with no access token") }
                
                let transaction = SwiftfinStore.dataStack.beginUnsafe()
                let newUser = transaction.create(Into<SwiftfinStore.Models.StoredUser>())
                newUser.username = response.user?.name ?? "SfUsername"
                newUser.id = response.user?.id ?? "SfID"
                newUser.appleTVID = ""
                
                let newAccessToken = transaction.create(Into<SwiftfinStore.Models.StoredAccessToken>())
                newAccessToken.value = accessToken
                newUser.accessToken = newAccessToken
                
                guard let userServer = try? SwiftfinStore.dataStack.fetchOne(From<SwiftfinStore.Models.StoredServer>(),
                                                                        [Where<SwiftfinStore.Models.StoredServer>("id == %@", server.id)])
                    else { fatalError("No stored server associated with given state server?") }
                
                guard let editUserServer = transaction.edit(userServer) else { fatalError("Can't get proxy for existing object?") }
                editUserServer.users.insert(newUser)
                
                return (editUserServer, newUser, transaction)
            })
            .handleEvents(receiveOutput: { [unowned self] (server, user, transaction) in
                setAuthHeader(with: user.accessToken?.value ?? "")
                try? transaction.commitAndWait()
                
                // Fetch for the right queue
                let currentServer = SwiftfinStore.dataStack.fetchExisting(server)!
                let currentUser = SwiftfinStore.dataStack.fetchExisting(user)!
                
                SwiftfinStore.Defaults.suite[.lastServerUserID] = user.id
                
                currentLogin = (server: currentServer.state, user: currentUser.state)
            })
            .map({ (_, user, _) in
                return user.state
            })
            .eraseToAnyPublisher()
    }
    
    func loginUser(server: SwiftfinStore.State.Server, user: SwiftfinStore.State.User) {
        JellyfinAPI.basePath = server.uri
        SwiftfinStore.Defaults.suite[.lastServerUserID] = user.id
        setAuthHeader(with: user.accessToken)
        currentLogin = (server: server, user: user)
    }
    
    func logout() {
        JellyfinAPI.basePath = ""
        setAuthHeader(with: "")
        SwiftfinStore.Defaults.suite[.lastServerUserID] = nil
        SwiftfinNotificationCenter.main.post(name: SwiftfinNotificationCenter.Keys.didSignOut, object: nil)
    }
    
    private func setAuthHeader(with accessToken: String) {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        var deviceName = UIDevice.current.name
        deviceName = deviceName.folding(options: .diacriticInsensitive, locale: .current)
        deviceName = String(deviceName.unicodeScalars.filter {CharacterSet.urlQueryAllowed.contains($0) })
        
        let platform: String
        #if os(tvOS)
        platform = "tvOS"
        #else
        platform = "iOS"
        #endif
        
        var header = "MediaBrowser "
        header.append("Client=\"Jellyfin \(platform)\", ")
        header.append("Device=\"\(deviceName)\", ")
        header.append("DeviceId=\"\(platform)_\(UIDevice.vendorUUIDString)_\(String(Date().timeIntervalSince1970))\", ")
        header.append("Version=\"\(appVersion ?? "0.0.1")\", ")
        header.append("Token=\"\(accessToken)\"")

        JellyfinAPI.customHeaders["X-Emby-Authorization"] = header
    }
}
