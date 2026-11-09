//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

final class DefaultsKeyCache {

    private let keys = NSCache<NSString, AnyObject>()

    init() {
        keys.countLimit = 256
    }

    func key<Value: Defaults.Serializable>(
        _ name: String,
        default defaultValue: Value,
        suiteName: String
    ) -> Defaults.Key<Value> {
        let identity = "\(suiteName.utf8.count):\(suiteName)\(name)" as NSString

        if let key = keys.object(forKey: identity) as? Defaults.Key<Value> {
            return key
        }

        let key = Defaults.Key(name, default: defaultValue, suite: UserDefaults(suiteName: suiteName)!)
        keys.setObject(key, forKey: identity)

        return key
    }
}
