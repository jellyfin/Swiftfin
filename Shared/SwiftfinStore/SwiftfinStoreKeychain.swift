//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import KeychainSwift

extension SwiftfinStore {
    
    enum Keychain {
        
        private static let keychainAccessGroup = "9R8RREG67J.me.vigue.jellyfin.sharedKeychain"
        
        private static let keychain: KeychainSwift = {
            let keychain = KeychainSwift()
            keychain.accessGroup = keychainAccessGroup
            return keychain
        }()
        
        static func getAuthToken(serverUserID: String) -> String? {
            return keychain.get("AccessToken_\(serverUserID)")
        }
        
        static func delete(serverUserID: String) {
            // TODO: todo
        }
    }
}
