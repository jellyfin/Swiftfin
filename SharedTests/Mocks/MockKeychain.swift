//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import KeychainSwift
@testable import Swiftfin_iOS

final class MockKeychain: KeychainStoring {

    private var dataStorage: [String: Data] = [:]
    private var stringStorage: [String: String] = [:]

    @discardableResult
    func set(_ value: Data, forKey key: String, withAccess access: KeychainSwiftAccessOptions?) -> Bool {
        dataStorage[key] = value
        return true
    }

    func getData(_ key: String) -> Data? {
        dataStorage[key]
    }

    func get(_ key: String) -> String? {
        stringStorage[key]
    }

    @discardableResult
    func set(_ value: String, forKey key: String, withAccess access: KeychainSwiftAccessOptions?) -> Bool {
        stringStorage[key] = value
        return true
    }

    @discardableResult
    func delete(_ key: String) -> Bool {
        let removedData = dataStorage.removeValue(forKey: key)
        let removedString = stringStorage.removeValue(forKey: key)

        return removedData != nil || removedString != nil
    }
}
