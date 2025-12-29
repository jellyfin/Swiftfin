//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Dictionary {

    func inserting(value: Value, for key: Key) -> Self {
        var copy = self
        copy[key] = value
        return copy
    }

    func removingValue(for key: Key) -> Self {
        var copy = self
        copy.removeValue(forKey: key)
        return copy
    }
}
