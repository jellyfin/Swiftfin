//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Defaults
import Foundation

extension SwiftfinStore {
    
    enum Defaults {
        
        static let suite: UserDefaults = {
            return UserDefaults(suiteName: "swiftfinstore-defaults")!
        }()
    }
}

extension Defaults.Keys {
    static let lastServerUserID = Defaults.Key<String?>("lastServerUserID", suite: SwiftfinStore.Defaults.suite)
}
