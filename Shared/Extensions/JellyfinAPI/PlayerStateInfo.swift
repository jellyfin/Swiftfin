//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension PlayerStateInfo {

    var position: Duration? {
        guard let positionTicks else { return nil }
        return Duration.microseconds(positionTicks / 10)
    }

    @available(*, deprecated, message: "Use `position` instead")
    var positionSeconds: Int? {
        guard let positionTicks else { return nil }
        return positionTicks / 10_000_000
    }
}
