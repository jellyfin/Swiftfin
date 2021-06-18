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
import Foundation
import JellyfinAPI
import KeychainSwift
import UIKit

#if os(tvOS)
import TVServices
#endif

final class SessionManager {
    static let current = SessionManager()
    fileprivate(set) var user: SignedInUser!
    fileprivate(set) var deviceID: String = ""
    fileprivate(set) var accessToken: String = ""

    #if os(tvOS)
    let tvUserManager = TVUserManager()
    #endif

    init() {
        let savedUserRequest = SignedInUser.fetchRequest()

        let savedUsers = try? PersistenceController.shared.container.viewContext.fetch(savedUserRequest)

        #if os(tvOS)
        savedUsers?.forEach { savedUser in
            if savedUser.appletv_id == tvUserManager.currentUserIdentifier ?? "" {
                self.user = savedUser
            }
        }
        #else
        user = savedUsers?.first
        #endif

        if user != nil {
            let authToken = getAuthToken(userID: user.user_id!)
            generateAuthHeader(with: authToken)
        }
    }

    fileprivate func generateAuthHeader(with authToken: String?) {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        var deviceName = UIDevice.current.name
        deviceName = deviceName.folding(options: .diacriticInsensitive, locale: .current)
        deviceName = deviceName.removeRegexMatches(pattern: "[^\\w\\s]")

        var header = "MediaBrowser "
        #if os(tvOS)
        header.append("Client=\"SwiftFin tvOS\", ")
        #else
        header.append("Client=\"SwiftFin iOS\", ")
        #endif
        header.append("Device=\"\(deviceName)\", ")
        #if os(tvOS)
        header.append("DeviceId=\"tvOS_\(UIDevice.current.identifierForVendor!.uuidString)_\(user?.user_id ?? "")\", ")
        deviceID = "tvOS_\(UIDevice.current.identifierForVendor!.uuidString)_\(user?.user_id ?? "")"
        #else
        header.append("DeviceId=\"iOS_\(UIDevice.current.identifierForVendor!.uuidString)_\(user?.user_id ?? "")\", ")
        deviceID = "iOS_\(UIDevice.current.identifierForVendor!.uuidString)_\(user?.user_id ?? "")"
        #endif
        header.append("Version=\"\(appVersion ?? "0.0.1")\", ")

        if authToken != nil {
            header.append("Token=\"\(authToken!)\"")
            accessToken = authToken!
        }

        JellyfinAPI.customHeaders["X-Emby-Authorization"] = header
    }

    fileprivate func getAuthToken(userID: String) -> String? {
        let keychain = KeychainSwift()
        keychain.accessGroup = "9R8RREG67J.me.vigue.jellyfin.sharedKeychain"
        return keychain.get("AccessToken_\(userID)")
    }

    func doesUserHaveSavedSession(userID: String) -> Bool {
        let savedUserRequest = SignedInUser.fetchRequest()
        savedUserRequest.predicate = NSPredicate(format: "user_id == %@", userID)
        let savedUsers = try? PersistenceController.shared.container.viewContext.fetch(savedUserRequest)

        if savedUsers!.isEmpty {
            return false
        }

        return true
    }

    func getSavedSession(userID: String) -> SignedInUser {
        let savedUserRequest = SignedInUser.fetchRequest()
        savedUserRequest.predicate = NSPredicate(format: "user_id == %@", userID)
        let savedUsers = try? PersistenceController.shared.container.viewContext.fetch(savedUserRequest)
        return savedUsers!.first!
    }

    func loginWithSavedSession(user: SignedInUser) {
        let accessToken = getAuthToken(userID: user.user_id!)

        self.user = user
        generateAuthHeader(with: accessToken)
        print(JellyfinAPI.customHeaders)
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("didSignIn"), object: nil)
    }

    func login(username: String, password: String) -> AnyPublisher<SignedInUser, Error> {
        generateAuthHeader(with: nil)

        return UserAPI.authenticateUserByName(authenticateUserByName: AuthenticateUserByName(username: username, pw: password))
            .map { response -> (SignedInUser, String?) in
                let user = SignedInUser(context: PersistenceController.shared.container.viewContext)
                user.username = response.user?.name
                user.user_id = response.user?.id

                #if os(tvOS)
                // user.appletv_id = tvUserManager.currentUserIdentifier ?? ""
                #endif

                return (user, response.accessToken)
            }
            .handleEvents(receiveOutput: { [unowned self] response, accessToken in
                user = response
                _ = try? PersistenceController.shared.container.viewContext.save()

                let keychain = KeychainSwift()
                keychain.accessGroup = "9R8RREG67J.me.vigue.jellyfin.sharedKeychain"
                keychain.set(accessToken!, forKey: "AccessToken_\(user.user_id!)")

                generateAuthHeader(with: accessToken)

                let nc = NotificationCenter.default
                nc.post(name: Notification.Name("didSignIn"), object: nil)
            })
            .map(\.0)
            .eraseToAnyPublisher()
    }

    func logout() {
        let keychain = KeychainSwift()
        keychain.accessGroup = "9R8RREG67J.me.vigue.jellyfin.sharedKeychain"
        keychain.delete("AccessToken_\(user?.user_id ?? "")")
        generateAuthHeader(with: nil)

        let deleteRequest = NSBatchDeleteRequest(objectIDs: [user.objectID])
        user = nil
        _ = try? PersistenceController.shared.container.viewContext.execute(deleteRequest)

        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("didSignOut"), object: nil)
    }
}
