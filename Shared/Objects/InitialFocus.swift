//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

protocol FocusTarget: Hashable, Identifiable {}

extension FocusTarget {

    var id: Self {
        self
    }
}

enum InitialFocus<Destination: FocusTarget> {

    case waiting
    case automatic
    case destination(Destination)
}
