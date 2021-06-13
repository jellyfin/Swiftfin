//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import CoreData
import KeychainSwift
import UIKit

final class SessionManager {
    
    static let shared = SessionManager()
    var user: SignedInUser?
    var authHeader: String?
    
    init() {
        let savedUserRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SignedInUser")
        let savedUsers = try? PersistenceController.shared.container.viewContext.fetch(savedUserRequest) as? [SignedInUser]
        user = savedUsers?.first
        
        let keychain = KeychainSwift()
        // need prefix
        keychain.accessGroup = "9R8RREG67J.me.vigue.jellyfin.sharedKeychain"
        guard let authToken = keychain.get("AccessToken_\(user?.user_id ?? "")") else {
            return
        }

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        var deviceName = UIDevice.current.name
        deviceName = deviceName.folding(options: .diacriticInsensitive, locale: .current)
        deviceName = deviceName.removeRegexMatches(pattern: "[^\\w\\s]")

        var header = "MediaBrowser "
        header.append("Client=\"SwiftFin\", ")
        header.append("Device=\"\(deviceName)\", ")
        header.append("DeviceId=\"\(user?.device_uuid ?? "")\", ")
        header.append("Version=\"\(appVersion ?? "0.0.1")\", ")
        header.append("Token=\"\(authToken)\"")

        self.authHeader = header
    }
}
