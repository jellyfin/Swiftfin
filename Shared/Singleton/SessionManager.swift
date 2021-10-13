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
import Foundation
import JellyfinAPI
import KeychainSwift
import UIKit

#if os(tvOS)
import TVServices
#endif

typealias CurrentLogin = (server: SwiftfinStore.Models.Server, user: SwiftfinStore.Models.User)

// MARK: NewSessionManager
final class SessionManager {
    
    // MARK: currentLogin
    private(set) var currentLogin: CurrentLogin!
    
    // MARK: main
    static let main = SessionManager()
    
    private let JellyfinDefaults = UserDefaults(suiteName: "jellyfin-defaults")!
    
    private init() {
        if let lastServerUserID = SwiftfinStore.Defaults.suite[.lastServerUserID],
           let userID = lastServerUserID.split(separator: "-")[safe: 1],
           let user = try? SwiftfinStore.dataStack.fetchOne(From<SwiftfinStore.Models.User>(),
                                                            [Where<SwiftfinStore.Models.User>("id == %@", userID)]) {
            // Strongly assuming that we didn't delete the server associate with the user
            guard let server = user.server, let accessToken = user.accessToken else { return }
            
            setAuthHeader(with: accessToken.value)
            currentLogin = (server: server, user: user)
        }
    }
    
    private func generateServerUserID(server: SwiftfinStore.Models.Server, user: SwiftfinStore.Models.User) -> String {
        return "\(server.id)-\(user.id)"
    }
    
    func fetchServers() -> [SwiftfinStore.Models.Server] {
        let servers = try! SwiftfinStore.dataStack.fetchAll(From<SwiftfinStore.Models.Server>())
        return servers
    }
    
    // Connects to a server at the given uri, storing if successful
    func connectToServer(with uri: String) -> AnyPublisher<SwiftfinStore.Models.Server, Error> {
        var uri = uri
        if !uri.contains("http") {
            uri = "https://" + uri
        }
        if uri.last == "/" {
            uri = String(uri.dropLast())
        }
        
        JellyfinAPI.basePath = uri
        
        return SystemAPI.getPublicSystemInfo()
            .map({ response -> (SwiftfinStore.Models.Server, UnsafeDataTransaction) in
                let transaction = SwiftfinStore.dataStack.beginUnsafe()
                let newServer = transaction.create(Into<SwiftfinStore.Models.Server>())
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
                return server
            })
            .eraseToAnyPublisher()
    }
    
    // Logs in a user with an associated server, storing if successful
    func loginUser(server: SwiftfinStore.Models.Server, username: String, password: String) -> AnyPublisher<SwiftfinStore.Models.User, Error> {
        setAuthHeader(with: "")
        
        return UserAPI.authenticateUserByName(authenticateUserByName: AuthenticateUserByName(username: username, pw: password))
            .map({ response -> (SwiftfinStore.Models.User, UnsafeDataTransaction) in
                
                guard let accessToken = response.accessToken else { fatalError("Received successful user with no access token") }
                
                let transaction = SwiftfinStore.dataStack.beginUnsafe()
                let newUser = transaction.create(Into<SwiftfinStore.Models.User>())
                newUser.username = response.user?.name ?? "SfUsername"
                newUser.id = response.user?.id ?? "SfID"
                newUser.appleTVID = ""
                
                let newAccessToken = transaction.create(Into<SwiftfinStore.Models.AccessToken>())
                newAccessToken.value = accessToken
                newUser.accessToken = newAccessToken
                
                let userServer = transaction.edit(server)
                userServer?.users.insert(newUser)
                
                return (newUser, transaction)
            })
            .handleEvents(receiveOutput: { [unowned self] (user, transaction) in
                setAuthHeader(with: user.accessToken?.value ?? "")
                try? transaction.commitAndWait()
                currentLogin = (server: server, user: user)
            })
            .map({ (user, _) in
                return user
            })
            .eraseToAnyPublisher()
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

//final class SessionManager {
//    static let current = SessionManager()
//    fileprivate(set) var user: SignedInUser!
//    fileprivate(set) var deviceID: String = ""
//    fileprivate(set) var accessToken: String = ""
//
//    #if os(tvOS)
//    let tvUserManager = TVUserManager()
//    #endif
//    let userDefaults = UserDefaults()
//
//    init() {
//        let savedUserRequest: NSFetchRequest<SignedInUser> = SignedInUser.fetchRequest()
//        let lastUsedUserID = userDefaults.string(forKey: "lastUsedUserID")
//        let savedUsers = try? PersistenceController.shared.container.viewContext.fetch(savedUserRequest)
//
//        #if os(tvOS)
//        savedUsers?.forEach { savedUser in
//            if savedUser.appletv_id == tvUserManager.currentUserIdentifier ?? "" {
//                self.user = savedUser
//            }
//        }
//        #else
//        if lastUsedUserID != nil {
//            savedUsers?.forEach { savedUser in
//                if savedUser.user_id ?? "" == lastUsedUserID! {
//                    user = savedUser
//                }
//            }
//        } else {
//            user = savedUsers?.first
//        }
//        #endif
//
//        if user != nil {
//            let authToken = getAuthToken(userID: user.user_id!)
//            generateAuthHeader(with: authToken, deviceID: user.device_uuid)
//        }
//    }
//
//    fileprivate func generateAuthHeader(with authToken: String?, deviceID devID: String?) {
//        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
//        var deviceName = UIDevice.current.name
//        deviceName = deviceName.folding(options: .diacriticInsensitive, locale: .current)
//        deviceName = String(deviceName.unicodeScalars.filter {CharacterSet.urlQueryAllowed.contains($0) })
//
//        var header = "MediaBrowser "
//        #if os(tvOS)
//        header.append("Client=\"Jellyfin tvOS\", ")
//        #else
//        header.append("Client=\"SwiftFin iOS\", ")
//        #endif
//
//        header.append("Device=\"\(deviceName)\", ")
//
//        if devID == nil {
//            LogManager.shared.log.info("Generating device ID...")
//            #if os(tvOS)
//            header.append("DeviceId=\"tvOS_\(UIDevice.current.identifierForVendor!.uuidString)_\(String(Date().timeIntervalSince1970))\", ")
//            deviceID = "tvOS_\(UIDevice.current.identifierForVendor!.uuidString)_\(String(Date().timeIntervalSince1970))"
//            #else
//            header.append("DeviceId=\"iOS_\(UIDevice.current.identifierForVendor!.uuidString)_\(String(Date().timeIntervalSince1970))\", ")
//            deviceID = "iOS_\(UIDevice.current.identifierForVendor!.uuidString)_\(String(Date().timeIntervalSince1970))"
//            #endif
//        } else {
//            LogManager.shared.log.info("Using stored device ID...")
//            header.append("DeviceId=\"\(devID!)\", ")
//            deviceID = devID!
//        }
//
//        header.append("Version=\"\(appVersion ?? "0.0.1")\", ")
//
//        if authToken != nil {
//            header.append("Token=\"\(authToken!)\"")
//            accessToken = authToken!
//        }
//
//        JellyfinAPI.customHeaders["X-Emby-Authorization"] = header
//    }
//
//    fileprivate func getAuthToken(userID: String) -> String? {
//        let keychain = KeychainSwift()
//        keychain.accessGroup = "9R8RREG67J.me.vigue.jellyfin.sharedKeychain"
//        return keychain.get("AccessToken_\(userID)")
//    }
//
//    func doesUserHaveSavedSession(userID: String) -> Bool {
//        let savedUserRequest: NSFetchRequest<SignedInUser> = SignedInUser.fetchRequest()
//        savedUserRequest.predicate = NSPredicate(format: "user_id == %@", userID)
//        let savedUsers = try? PersistenceController.shared.container.viewContext.fetch(savedUserRequest)
//
//        if savedUsers!.isEmpty {
//            return false
//        }
//
//        return true
//    }
//
//    func getSavedSession(userID: String) -> SignedInUser {
//        let savedUserRequest: NSFetchRequest<SignedInUser> = SignedInUser.fetchRequest()
//        savedUserRequest.predicate = NSPredicate(format: "user_id == %@", userID)
//        let savedUsers = try? PersistenceController.shared.container.viewContext.fetch(savedUserRequest)
//        return savedUsers!.first!
//    }
//
//    func loginWithSavedSession(user: SignedInUser) {
//        let accessToken = getAuthToken(userID: user.user_id!)
//        userDefaults.set(user.user_id!, forKey: "lastUsedUserID")
//        self.user = user
//        generateAuthHeader(with: accessToken, deviceID: user.device_uuid)
//        print(JellyfinAPI.customHeaders)
//        let nc = NotificationCenter.default
//        nc.post(name: Notification.Name("didSignIn"), object: nil)
//    }
//
//    func login(username: String, password: String) -> AnyPublisher<SignedInUser, Error> {
//        generateAuthHeader(with: nil, deviceID: nil)
//
//        return UserAPI.authenticateUserByName(authenticateUserByName: AuthenticateUserByName(username: username, pw: password))
//            .map { response -> (SignedInUser, String?) in
//                let user = SignedInUser(context: PersistenceController.shared.container.viewContext)
//                user.username = response.user?.name
//                user.user_id = response.user?.id
//                user.device_uuid = self.deviceID
//
//                #if os(tvOS)
//                let descriptor: TVAppProfileDescriptor = TVAppProfileDescriptor(name: user.username!)
//                self.tvUserManager.shouldStorePreferenceForCurrentUser(to: descriptor) { should in
//                    if should {
//                        user.appletv_id = self.tvUserManager.currentUserIdentifier ?? ""
//                    }
//                }
//                #endif
//
//                return (user, response.accessToken)
//            }
//            .handleEvents(receiveOutput: { [unowned self] response, accessToken in
//                user = response
//                _ = try? PersistenceController.shared.container.viewContext.save()
//
//                let keychain = KeychainSwift()
//                keychain.accessGroup = "9R8RREG67J.me.vigue.jellyfin.sharedKeychain"
//                keychain.set(accessToken!, forKey: "AccessToken_\(user.user_id!)")
//
//                generateAuthHeader(with: accessToken, deviceID: user.device_uuid)
//
//                let nc = NotificationCenter.default
//                nc.post(name: Notification.Name("didSignIn"), object: nil)
//            })
//            .map(\.0)
//            .eraseToAnyPublisher()
//    }
//
//    func logout() {
//        let nc = NotificationCenter.default
//        nc.post(name: Notification.Name("didSignOut"), object: nil)
//        let keychain = KeychainSwift()
//        keychain.accessGroup = "9R8RREG67J.me.vigue.jellyfin.sharedKeychain"
//        keychain.delete("AccessToken_\(user?.user_id ?? "")")
//        generateAuthHeader(with: nil, deviceID: nil)
//        if user != nil {
//            let deleteRequest = NSBatchDeleteRequest(objectIDs: [user.objectID])
//            user = nil
//            _ = try? PersistenceController.shared.container.viewContext.execute(deleteRequest)
//        }
//    }
//}
