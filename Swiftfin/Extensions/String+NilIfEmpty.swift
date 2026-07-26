//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

extension String? {

    var nilIfEmpty: String? {
        guard let self, self.isNotEmpty else { return nil }

        return self
    }
}

extension String {

    var nilIfEmpty: String? {
        isNotEmpty ? self : nil
    }
}
