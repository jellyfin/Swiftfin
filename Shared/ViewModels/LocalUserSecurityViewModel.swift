//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import KeychainSwift

final class LocalUserSecurityViewModel: ViewModel {

    @Injected(\.keychainService)
    var keychain

    func check(oldPin: String) throws {
        let user = try authenticatedUser

        if let storedPin = keychain.get("\(user.id)-pin") {
            if oldPin != storedPin {
                throw ErrorMessage(L10n.incorrectPinForUser(user.username))
            }
        }
    }

    func set(newPolicy: LocalUserAccessPolicy, newPin: String, newPinHint: String) throws {
        let user = try authenticatedUser

        if newPolicy == .requirePin {
            keychain.set(newPin, forKey: "\(user.id)-pin")
        } else {
            keychain.delete("\(user.id)-pin")
        }

        user.accessPolicy = newPolicy
        user.pinHint = newPinHint
    }
}
