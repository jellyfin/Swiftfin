//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

struct PressCommandAction {

    let title: String
    let press: UIPress.PressType
    let action: () -> Void
}

extension PressCommandAction: Equatable {

    static func == (lhs: PressCommandAction, rhs: PressCommandAction) -> Bool {
        lhs.press == rhs.press
    }
}
