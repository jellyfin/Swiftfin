//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension NamedURL: Displayable {

    var displayTitle: String {
        name ?? url ?? .emptyDash
    }
}

extension NamedURL: SystemImageable {

    var systemImage: String {
        "arrow.up.right.square"
    }
}
