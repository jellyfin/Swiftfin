//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

extension URLComponents {

    func addingQueryItem(key: String, value: String?) -> Self {
        var copy = self

        if copy.queryItems == nil {
            copy.queryItems = []
        }

        copy.queryItems?.append(.init(name: key, value: value))
        return copy
    }
}
