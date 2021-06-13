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

final class SessionManager {
    static let current = SessionManager()
    fileprivate(set) var user: SignedInUser!
    fileprivate(set) var authHeader: String!
    fileprivate(set) var deviceIDString: String

    init() {
        let savedUserRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SignedInUser")
        let savedUsers = try? PersistenceController.shared.container.viewContext.fetch(savedUserRequest) as? [SignedInUser]
        user = savedUsers?.first

        let keychain = KeychainSwift()
        keychain.accessGroup = "9R8RREG67J.me.vigue.jellyfin.sharedKeychain"
        if let deviceID = keychain.get("DeviceIDString") {
            self.deviceIDString = deviceID
        } else {
            self.deviceIDString = UUID().uuidString
            keychain.set(deviceIDString, forKey: "DeviceIDString")
        }

        guard let authToken = keychain.get("AccessToken_\(user?.user_id ?? "")") else {
            return
        }

        updateHeader(with: authToken)
    }

    fileprivate func updateHeader(with authToken: String?) {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        var deviceName = UIDevice.current.name
        deviceName = deviceName.folding(options: .diacriticInsensitive, locale: .current)
        deviceName = deviceName.removeRegexMatches(pattern: "[^\\w\\s]")

        var header = "MediaBrowser "
        header.append("Client=\"SwiftFin\", ")
        header.append("Device=\"\(deviceName)\", ")
        header.append("DeviceId=\"\(deviceIDString)\", ")
        header.append("Version=\"\(appVersion ?? "0.0.1")\", ")
        if let token = authToken {
            header.append("Token=\"\(token)\"")
        }

        authHeader = header
        JellyfinAPI.customHeaders["X-Emby-Authorization"] = authHeader
    }

    func login(username: String, password: String) -> AnyPublisher<SignedInUser, Error> {
        updateHeader(with: nil)

        return UserAPI.authenticateUserByName(authenticateUserByName: AuthenticateUserByName(username: username, pw: password))
            .map { [unowned self] response -> (SignedInUser, String?) in
                let user = SignedInUser(context: PersistenceController.shared.container.viewContext)
                user.device_uuid = deviceIDString
                user.username = response.user?.name
                user.user_id = response.user?.id
                return (user, response.accessToken)
            }
            .handleEvents(receiveOutput: { [unowned self] response, accessToken in
                user = response
                _ = try? PersistenceController.shared.container.viewContext.save()
                if let userID = user.user_id,
                   let token = accessToken
                {
                    let keychain = KeychainSwift()
                    keychain.accessGroup = "9R8RREG67J.me.vigue.jellyfin.sharedKeychain"
                    keychain.set(token, forKey: "AccessToken_\(userID)")
                }
                updateHeader(with: accessToken)
            })
            .map(\.0)
            .eraseToAnyPublisher()
    }

    func logout() throws {
        let keychain = KeychainSwift()
        keychain.accessGroup = "9R8RREG67J.me.vigue.jellyfin.sharedKeychain"
        keychain.delete("AccessToken_\(user.user_id ?? "")")
        JellyfinAPI.customHeaders["X-Emby-Authorization"] = nil
        user = nil
        authHeader = nil

        let userRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "SignedInUser")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: userRequest)

        try PersistenceController.shared.container.viewContext.execute(deleteRequest)
    }
}
